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

## Recommended backend next steps

1. Create an ingestion API that accepts social share URLs and normalises creator metadata.
2. Add platform-specific extractors for YouTube, TikTok, and Instagram transcripts/captions.
3. Build a structured recipe generation pipeline with confidence scoring and provenance per field.
4. Persist recipes, books, and user edits in a real backend such as Supabase or Postgres.
5. Add auth, sync, background import jobs, image extraction, and share extensions.
