# Cooksy Production Readiness

This runbook covers the minimum deploy and verification path for taking Cooksy from local MVP to a production-shaped beta.

## Supabase deploy order

1. Apply migrations in order:
   - `supabase/migrations/20260404100000_cooksy_core.sql`
   - `supabase/migrations/20260404223000_recipe_production_fields.sql`
   - `supabase/migrations/20260404233000_auth_ownership_rls.sql`
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
EXPO_PUBLIC_RECIPE_IMPORT_MODE=auto
EXPO_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
```

Use `mock` only for local product work. Use `auto` or `remote` for integration verification.

## Verification checklist

Run these checks after every schema or function deploy:

1. Start the app and confirm an anonymous session is created.
2. Import a YouTube URL and verify a `recipe_import_jobs` row is created for the current user.
3. Poll the import flow until the recipe reaches `ready` or `failed`.
   The current backend advances jobs by persisted stage transitions on each status check, not by elapsed wall-clock time.
4. Confirm `recipes`, `recipe_ingredients`, and `recipe_steps` rows are persisted for completed imports.
5. Edit a recipe and confirm the updated title or ingredients persist after reload.
6. Create a book, add a recipe to it, reload, and confirm the relationship remains.
7. Visit the recipe detail screen for a processing recipe and confirm it resumes polling.
8. Fail an import intentionally and confirm the UI exposes a retry path instead of a dead end.
9. Try an unsupported URL and confirm the user gets a clear validation error before or during import creation.
10. Trigger repeated imports and confirm duplicate in-flight jobs are reused and the rate limit returns a clear error once exceeded.

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

Recommended first alerts:

- import function failure rate
- import timeout rate
- import rate-limit frequency
- auth bootstrap failure
- recipe persistence failure

## Remaining launch-critical work

This repo is now structured for production, but these still need implementation before a public release:

1. Replace time-based job progression with a real worker/extractor pipeline.
2. Add a real analytics and crash-reporting provider.
3. Add source validation and rate limiting around import creation.
4. Harden unsupported-link and partial-data messaging.
5. Add signed-in account UX if anonymous-only sessions are no longer sufficient.
