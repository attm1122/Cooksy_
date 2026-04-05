# Cooksy: Recipe Builder

Cooksy is a production-minded Expo MVP for a cross-platform recipe app that turns shared YouTube, TikTok, and Instagram cooking links into structured recipes people can save, edit, organise into books, and cook from.

## Stack

- Expo + React Native + Expo Router
- TypeScript with strict mode
- NativeWind for shared styling
- TanStack Query for async flows
- Zustand for local product state
- React Hook Form + Zod for validation
- Lucide React Native icons
- Jest + Testing Library for tests

## Run

```bash
npm install
cp .env.example .env
npm run start
npm run web
npm run ios
npm run android
npm run test
npm run lint
npm run typecheck
npm run build:web:release
npm run release:check
```

## Product scope

This MVP includes:

- Home import flow
- Processing state experience
- Recipe detail
- Recipe editing
- Recipe books and book detail
- Full recipes library
- Cooking mode
- Profile/settings shell

Supported import links:

- YouTube watch, shorts, and `youtu.be` share links
- TikTok video share links
- Instagram reel/post share links

## Architecture

```text
app/                    Expo Router routes and navigation shells
src/components/         Shared UI building blocks
src/features/           Reserved for deeper feature slices as flows expand
src/hooks/              Query hooks and reusable stateful logic
src/lib/                Query client and Zod schemas
src/mocks/              Realistic recipe and recipe-book fixtures
src/services/           Mock async service layer for future backend swap-in
src/store/              Zustand state for import flow, books, recipes, cooking
src/theme/              Cooksy design tokens
src/types/              App domain models
src/utils/              Small formatters and helpers
tests/                  Schema, component, and store coverage
assets/                 Brand logo assets and app icon concepts
docs/                   Deployment and production runbooks
```

## Design system notes

Cooksy is intentionally consumer-first:

- Cream surfaces with controlled use of yellow
- Rounded cards and soft elevation
- Tight, bold typography using Inter as an open alternative to Uber-style product typography
- Reusable tokens for color, spacing, radius, shadow, typography, and icon sizes
- Brand logo built as code and SVG assets with light, dark, horizontal, and icon-only variants

Core brand colors:

- Primary Yellow: `#F5C400`
- Soft Yellow: `#FFF6CC`
- Cream Background: `#FFFDF7`
- Ink: `#111111`
- Soft Ink: `#262626`

## What is mocked

The current repo is intentionally frontend-complete but backend-light:

- Recipe import/generation is mocked with staged async progress
- Recipes and recipe books use mock fixtures
- Save/edit/book actions are stored locally in Zustand
- Source extraction and AI inference are represented by service stubs, not real ingestion

## Backend foundation added

This repo now includes the first real backend seam:

- `src/services/import-service.ts` introduces a job-based import pipeline
- `src/lib/env.ts` and `src/lib/supabase.ts` add environment-aware backend wiring
- `supabase/migrations/20260404100000_cooksy_core.sql` defines import jobs, recipes, ingredients, steps, books, and join tables
- `supabase/functions/import-recipe/index.ts` provides the first import edge-function contract for creating and polling jobs
- `supabase/migrations/20260404223000_recipe_production_fields.sql` adds production-oriented recipe fields and a unique persisted linkage from import jobs to recipes

### Current production-ready backend slice

The import flow now supports a more realistic persisted lifecycle:

- import jobs progress on the backend through persisted stage transitions
- completed jobs persist a recipe row plus ingredient and step rows
- the app hydrates recent persisted recipes on startup and merges them into local state
- save-first imports can now survive beyond a single frontend session once the Supabase migrations and edge function are deployed
- repeated imports for the same in-flight source reuse the existing backend job instead of creating duplicates

The next persistence slice is also in place:

- recipe edits can write through the backend-facing service layer
- recipe books hydrate on startup
- book creation and recipe-to-book membership changes can persist through Supabase when configured

### Auth and ownership

Cooksy now assumes a user-scoped backend shape:

- the app bootstraps a Supabase session on startup
- data models are moving behind user ownership
- the latest migration adds row-level-security-ready ownership columns and policies
- the import edge function now expects an authenticated JWT

For best results in Supabase:

1. Enable Anonymous Auth if you want the MVP to work without a full sign-up flow yet.
2. Deploy the latest migrations before testing production persistence.
3. Deploy the `import-recipe` edge function after switching `verify_jwt` on.

### Environment

Copy `.env.example` to `.env` and fill in:

```bash
EXPO_PUBLIC_RECIPE_IMPORT_MODE=auto
EXPO_PUBLIC_SUPABASE_URL=https://qirjjbmrgtailifhmakp.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=...
```

Modes:

- `mock`: always use the local mocked import worker
- `remote`: call the deployed Supabase edge function
- `auto`: use remote when configured, otherwise fall back to mock

The Supabase project ref currently wired into this repo is `qirjjbmrgtailifhmakp`.

### Current backend limitation

The remote ingestion path now has a real contract and persistence model, and import jobs can be resumed safely across app restarts. The next big backend step is still a fully independent worker/extractor layer so imports can finish without any client polling at all.

## Production operations

Cooksy now includes the first operational production layer:

- `src/lib/analytics.ts` for event instrumentation seams
- `src/lib/monitoring.ts` for error/reporting seams
- retryable import UX for failed recipe jobs
- background resumption for processing recipe detail views
- a Supabase ops health endpoint at `supabase/functions/ops-health`
- a deployment runbook in `docs/production-readiness.md`

The default analytics and monitoring clients only log locally. Swap them with a provider like PostHog, Segment, Sentry, or Bugsnag before launch.

The backend now also rejects unsupported source URLs and applies a lightweight per-user import limit to reduce duplicate or abusive import creation before a fuller queueing system is in place.

## Vercel release build

Cooksy ships the web target as a static Expo export on Vercel.

- `npm run build:web:release` exports the app and verifies the generated bundle
- `npm run release:check` runs the full local release gate: lint, types, tests, and verified web export
- `vercel.json` is configured to:
  - build with `npm run build:web:release`
  - serve `dist`
  - cache hashed Expo assets aggressively
  - keep SPA rewrites and basic security headers in place

Before a production promote on Vercel, make sure these env vars are present:

- `EXPO_PUBLIC_RECIPE_IMPORT_MODE`
- `EXPO_PUBLIC_SUPABASE_URL`
- `EXPO_PUBLIC_SUPABASE_ANON_KEY`
- `EXPO_PUBLIC_REVENUECAT_APPLE_API_KEY`
- `EXPO_PUBLIC_REVENUECAT_GOOGLE_API_KEY`
- `EXPO_PUBLIC_REVENUECAT_ENTITLEMENT`
- `EXPO_PUBLIC_WEB_BILLING_URL`

## Recommended backend next steps

1. Add a real background worker that claims queued `recipe_import_jobs` and advances each stage in the database.
2. Connect platform-specific ingestion adapters for YouTube, TikTok, and Instagram transcript/caption extraction.
3. Add an LLM normalization step that emits structured recipe JSON plus provenance and per-field confidence.
4. Persist completed normalized recipes into relational `recipes`, `recipe_ingredients`, and `recipe_steps` rows instead of only `normalized_recipe` JSON.
5. Add auth, per-user recipe ownership, sync, background retries, and media enrichment.
