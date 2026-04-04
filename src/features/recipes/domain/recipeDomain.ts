import type { RawRecipeContext, Recipe, SourcePlatform, ThumbnailSource } from "@/features/recipes/types";

let localRecipeCounter = 0;

const nowIso = () => new Date().toISOString();

export const createRecipeId = (platform: SourcePlatform) => {
  localRecipeCounter += 1;
  return `${platform}-recipe-${localRecipeCounter}`;
};

export const buildProcessingTitle = (platform: SourcePlatform) =>
  platform === "youtube" ? "Saved YouTube recipe" : platform === "tiktok" ? "Saved TikTok recipe" : "Saved Instagram recipe";

export const createEmptyRecipe = ({
  id,
  sourceUrl,
  sourcePlatform,
  thumbnailUrl,
  thumbnailSource,
  thumbnailFallbackStyle,
  rawExtraction
}: {
  id: string;
  sourceUrl: string;
  sourcePlatform: SourcePlatform;
  thumbnailUrl?: string | null;
  thumbnailSource: ThumbnailSource;
  thumbnailFallbackStyle?: string | null;
  rawExtraction?: RawRecipeContext;
}): Recipe => {
  const timestamp = nowIso();

  return {
    id,
    sourceUrl,
    sourcePlatform,
    sourceCreator: rawExtraction?.creator ?? null,
    sourceTitle: rawExtraction?.title ?? null,
    status: "processing",
    title: buildProcessingTitle(sourcePlatform),
    description: "Cooksy is extracting the original post and reconstructing it into a recipe you can actually cook.",
    servings: null,
    prepTimeMinutes: null,
    cookTimeMinutes: null,
    totalTimeMinutes: null,
    ingredients: [
      {
        id: `${id}-placeholder-ingredient`,
        name: "Recipe details loading",
        quantity: null,
        unit: null,
        note: "Cooksy is extracting ingredients from the source content.",
        inferred: true
      }
    ],
    steps: [
      {
        id: `${id}-placeholder-step`,
        order: 1,
        instruction: "Cooksy is reconstructing the method from the original post.",
        inferred: true
      }
    ],
    thumbnailUrl: thumbnailUrl ?? null,
    thumbnailSource,
    thumbnailFallbackStyle: thumbnailFallbackStyle ?? null,
    confidenceScore: 0,
    confidenceReport: {
      score: 0,
      warnings: [],
      missingFields: ["Recipe is still processing"],
      lowConfidenceAreas: ["Ingredients", "Steps"]
    },
    inferredFields: [],
    missingFields: ["Recipe is still processing"],
    validationWarnings: [],
    rawExtraction,
    createdAt: timestamp,
    updatedAt: timestamp,
    isSynced: false
  };
};
