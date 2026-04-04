import { getThumbnailFromUrl } from "@/features/recipes/services/thumbnailService";
import { mockRecipes } from "@/mocks/recipes";
import type { ImportJob } from "@/types/ingestion";
import type { Recipe, SourcePlatform } from "@/types/recipe";

const nowIso = () => new Date().toISOString();

export const inferPlatformFromUrl = (url: string): SourcePlatform => {
  if (url.includes("tiktok")) {
    return "tiktok";
  }

  if (url.includes("instagram")) {
    return "instagram";
  }

  return "youtube";
};

export const buildMockImportedRecipe = async (url: string): Promise<Recipe> => {
  const thumbnail = await getThumbnailFromUrl(url);

  return {
    ...mockRecipes[0],
    id: `imported-${inferPlatformFromUrl(url)}-${Date.now()}`,
    title: "Cooksy Imported Chicken Orzo",
    description: "A backend-ready mock import showing how Cooksy will ingest short-form cooking links into a polished recipe.",
    heroNote: "Generated from a shared video link with structured ingredients, steps, and inferred timings for home cooks.",
    imageLabel: "Imported chicken orzo skillet",
    thumbnailUrl: thumbnail.thumbnailUrl,
    thumbnailSource: thumbnail.thumbnailSource,
    thumbnailFallbackStyle: thumbnail.thumbnailFallbackStyle,
    source: {
      creator: "Imported Creator",
      url,
      platform: inferPlatformFromUrl(url)
    },
    confidence: "medium",
    confidenceNote: "Quantities and simmer timing were inferred from visible pan cues and creator narration."
  };
};

export const buildMockImportJob = (sourceUrl: string): ImportJob => {
  const createdAt = nowIso();

  return {
    id: `mock-job-${Date.now()}`,
    sourceUrl,
    sourcePlatform: inferPlatformFromUrl(sourceUrl),
    status: "queued",
    progress: 0.08,
    detail: {
      label: "Queued",
      description: "Waiting to start import"
    },
    createdAt,
    updatedAt: createdAt
  };
};
