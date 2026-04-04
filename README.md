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

### Environment

Copy `.env.example` to `.env` and fill in:

```bash
EXPO_PUBLIC_RECIPE_IMPORT_MODE=mock
EXPO_PUBLIC_SUPABASE_URL=...
EXPO_PUBLIC_SUPABASE_ANON_KEY=...
```

Modes:

- `mock`: always use the local mocked import worker
- `remote`: call the deployed Supabase edge function
- `auto`: use remote when configured, otherwise fall back to mock

### Current backend limitation

The remote ingestion path now has a real contract and persistence model, but it still needs a worker that advances queued jobs through extraction, ingredient parsing, and recipe generation. Until that worker exists, keep the app in `mock` mode for local product work.

## Recommended backend next steps

1. Add a real background worker that claims queued `recipe_import_jobs` and advances each stage in the database.
2. Connect platform-specific ingestion adapters for YouTube, TikTok, and Instagram transcript/caption extraction.
3. Add an LLM normalization step that emits structured recipe JSON plus provenance and per-field confidence.
4. Persist completed normalized recipes into relational `recipes`, `recipe_ingredients`, and `recipe_steps` rows instead of only `normalized_recipe` JSON.
5. Add auth, per-user recipe ownership, sync, background retries, and media enrichment.
