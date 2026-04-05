# Cooksy Production Readiness

This runbook covers the minimum deploy and verification path for taking Cooksy from local MVP to a production-shaped beta.

## Web release gate

Before promoting a Vercel deployment, run:

```bash
npm run release:check
```

This now verifies:

- lint
- TypeScript
- test suite
- successful Expo web export
- generated web bundles do not contain `import.meta` regressions that can white-screen production

Before native release builds, also run:

```bash
npm run release:mobile:check
```

And confirm:

- [`eas.json`](/Users/aubreymazinyi/Documents/Playground/Cooksy_/eas.json) is committed
- [`app.json`](/Users/aubreymazinyi/Documents/Playground/Cooksy_/app.json) has the intended `version`, iOS `buildNumber`, and Android `versionCode`

## Supabase deploy order

1. Apply migrations in order:
   - `supabase/migrations/20260404100000_cooksy_core.sql`
   - `supabase/migrations/20260404223000_recipe_production_fields.sql`
   - `supabase/migrations/20260404233000_auth_ownership_rls.sql`
   - `supabase/migrations/20260404235500_raw_extraction.sql`
   - `supabase/migrations/20260405013000_save_recipe_graph.sql`
2. Set Edge Function secrets:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
3. Enable Anonymous Auth if you want the current no-signup onboarding to keep working.
4. Deploy Edge Functions:
   - `import-recipe`
   - `ops-health`

## Client environment

Set the Expo public variables in local development and your build pipeline:

```bash
# Core configuration
EXPO_PUBLIC_RECIPE_IMPORT_MODE=remote
EXPO_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon-key>

# Extraction layer (optional but recommended)
EXPO_PUBLIC_RAPIDAPI_KEY=<your-rapidapi-key>
EXPO_PUBLIC_RAPIDAPI_HOST=tiktok-api.p.rapidapi.com
EXPO_PUBLIC_ENABLE_TIKTOK_SCRAPING=true
EXPO_PUBLIC_ENABLE_INSTAGRAM_SCRAPING=true
EXPO_PUBLIC_EXTRACTION_TIMEOUT_MS=30000
```

Use `mock` only for local product work. Use `auto` or `remote` for integration verification.

For Vercel web production, also set:

```bash
EXPO_PUBLIC_REVENUECAT_APPLE_API_KEY=<optional for native preview parity>
EXPO_PUBLIC_REVENUECAT_GOOGLE_API_KEY=<optional for native preview parity>
EXPO_PUBLIC_REVENUECAT_ENTITLEMENT=cooksy_pro
EXPO_PUBLIC_WEB_BILLING_URL=<hosted checkout or billing portal URL>
```

See [docs/extraction-layer.md](./extraction-layer.md) for detailed extraction configuration.

## Extraction Layer Configuration

The extraction layer is critical for production. Platform support levels:

| Platform | Support Level | Recommended Config |
|----------|--------------|-------------------|
| YouTube | ⭐⭐⭐⭐⭐ Excellent | Works out of the box |
| TikTok | ⭐⭐⭐☆☆ Good | Enable RapidAPI for best results |
| Instagram | ⭐⭐☆☆☆ Limited | Scraping often blocked |

### YouTube Setup
No additional configuration needed. Extraction uses:
- oEmbed API for metadata
- Watch page scraping for transcripts
- ~95% success rate for public videos

### TikTok Setup
For reliable TikTok extraction:

1. Sign up for RapidAPI
2. Subscribe to a TikTok API (e.g., "TikTok API" by Huy Pham)
3. Add credentials to environment:
   ```bash
   EXPO_PUBLIC_RAPIDAPI_KEY=your_key_here
   EXPO_PUBLIC_RAPIDAPI_HOST=tiktok-api.p.rapidapi.com
   ```

Without RapidAPI, enable scraping (lower success rate):
```bash
EXPO_PUBLIC_ENABLE_TIKTOK_SCRAPING=true
```

### Instagram Setup
Instagram actively blocks automated access. Options:

1. **Basic scraping** (limited success):
   ```bash
   EXPO_PUBLIC_ENABLE_INSTAGRAM_SCRAPING=true
   ```

2. **Instagram Basic Display API** (requires app review):
   - Apply for Instagram Basic Display API
   - Implement OAuth flow
   - Update extraction adapter

3. **Third-party service** (recommended for production):
   - Use Apify, ScrapingBee, or similar
   - Configure via custom adapter
## Verification checklist

Run these checks after every schema or function deploy:

1. Start the app and confirm an anonymous session is created.
2. Import a YouTube URL and verify a `recipe_import_jobs` row is created for the current user.
   - Verify transcript is extracted
   - Check thumbnail quality
3. Poll the import flow until the recipe reaches `ready` or `failed`.
   The current backend advances jobs by persisted stage transitions on each status check, not by elapsed wall-clock time.
4. Confirm `recipes`, `recipe_ingredients`, and `recipe_steps` rows are persisted for completed imports.
5. Edit a recipe and confirm the updated title or ingredients persist after reload.
6. Create a book, add a recipe to it, reload, and confirm the relationship remains.
7. Visit the recipe detail screen for a processing recipe and confirm it resumes polling.
8. Fail an import intentionally and confirm the UI exposes a retry path instead of a dead end.
9. Try an unsupported URL and confirm the user gets a clear validation error before or during import creation.
10. Trigger repeated imports and confirm duplicate in-flight jobs are reused and the rate limit returns a clear error once exceeded.
11. Open the deployed Vercel site, hard-refresh, and confirm the app boots without a white screen or console syntax errors.
12. Verify deep links such as `/recipe/<id>` and `/onboarding` resolve correctly through Vercel rewrites.
13. Confirm the public production URL is not blocked by Vercel Authentication before launch.

### Extraction-specific verification

14. Test YouTube import with transcript extraction:
    - URL: `https://www.youtube.com/watch?v=example`
    - Verify transcript segments are extracted
    - Check confidence score is high (>70)

15. Test TikTok import:
    - URL: `https://www.tiktok.com/@username/video/123456`
    - Verify creator and description extracted
    - Check for recipe hints in OCR text

16. Test rate limiting:
    - Attempt 15 rapid imports
    - Verify 429 response after limit
    - Check retry-after header

## Native release profiles

Cooksy ships with these EAS profiles in [`eas.json`](/Users/aubreymazinyi/Documents/Playground/Cooksy_/eas.json):

- `development`: dev-client internal builds
- `preview`: internal QA/TestFlight/Internal Testing builds
- `production`: store-ready builds with native version auto-increment

Recommended commands:

```bash
npm run build:ios:production
npm run build:android:production
npm run submit:ios:production
npm run submit:android:production
```

## Ops health endpoint

`ops-health` is an authenticated function meant for quick smoke checks.

Expected response shape:

```json
{
  "ok": true,
  "timestamp": "2026-04-04T12:00:00.000Z",
  "userId": "uuid",
  "checks": {
    "recipes": 12,
    "books": 4,
    "importJobs": 3
  }
}
```

Use it to verify:

- JWT auth is working
- RLS allows the current user to read their data
- the app has end-to-end connectivity to Supabase

## Monitoring hooks to replace before launch

Wire these seams to your real providers:

- `src/lib/analytics.ts`
- `src/lib/monitoring.ts`

Recommended first events:

- import started
- import completed
- import failed
- import retried
- recipe updated
- book created
- add/remove recipe from book
- extraction succeeded
- extraction failed (with platform)

Recommended first alerts:

- import function failure rate
- import timeout rate
- import rate-limit frequency
- auth bootstrap failure
- recipe persistence failure
- extraction failure rate by platform
- low confidence recipe rate

## Monitoring extraction health

Track these metrics for the extraction layer:

```typescript
import { getExtractionStatus } from "@/features/recipes/extraction";

const status = getExtractionStatus();
// Track: cache hit rate, rate limit status, adapter availability
```

Recommended thresholds:
- YouTube extraction success rate: >90%
- TikTok extraction success rate: >70% (with RapidAPI)
- Average extraction time: <10s
- Cache hit rate: >30%

## Remaining launch-critical work

This repo is now structured for production, but these still need implementation before a public release:

1. ~~Replace time-based job progression with a real worker/extractor pipeline.~~ ✅ DONE
   - YouTube: Full transcript extraction
   - TikTok: RapidAPI + scraping fallback
   - Instagram: Limited scraping (consider API alternative)

2. Add a real analytics and crash-reporting provider.
3. Add source validation and rate limiting around import creation.
4. Harden unsupported-link and partial-data messaging.
5. Add signed-in account UX if anonymous-only sessions are no longer sufficient.
6. Set up extraction monitoring dashboards.

## Troubleshooting common issues

### Extraction timeouts
- Increase `EXPO_PUBLIC_EXTRACTION_TIMEOUT_MS`
- Check network connectivity
- Verify platform rate limits

### Low confidence scores
- Check transcript quality
- Verify ingredient/step extraction
- Review signal weights in sourceEvidence.ts

### TikTok extraction failing
- Verify RapidAPI key is valid
- Check API quota limits
- Enable scraping fallback

### Instagram always failing
- Expected behavior - Instagram blocks scrapers
- Consider Instagram Basic Display API
- Implement manual recipe entry
