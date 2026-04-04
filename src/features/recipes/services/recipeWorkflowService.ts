import { createEmptyRecipe, createRecipeId } from "@/features/recipes/domain/recipeDomain";
import { ExtractionFailedError, RecipeReconstructionError } from "@/features/recipes/lib/errors";
import { detectPlatformFromUrl } from "@/features/recipes/lib/platform";
import { extractRecipeContextFromUrl } from "@/features/recipes/services/extractionService";
import { getThumbnailFromContext, getThumbnailFromUrl, generateFallbackThumbnailStyle } from "@/features/recipes/services/thumbnailService";
import { reconstructRecipe } from "@/features/recipes/services/recipeReconstructionService";
import { recipeRepository } from "@/features/recipes/services/recipeRepository";
import type { Recipe, ReconstructionResult, SourcePlatform } from "@/features/recipes/types";

export type WorkflowStage = "queued" | "extracting" | "identifying_ingredients" | "building_steps" | "completed" | "failed";

type WorkflowCallbacks = {
  onStageChange?: (stage: WorkflowStage, recipeId: string) => void;
};

const enrichProcessingRecipe = async (url: string, platform: SourcePlatform) => {
  const thumbnail = await getThumbnailFromUrl(url);

  return {
    thumbnailUrl: thumbnail.thumbnailUrl,
    thumbnailSource: thumbnail.thumbnailSource,
    thumbnailFallbackStyle: thumbnail.thumbnailFallbackStyle ?? generateFallbackThumbnailStyle("Cooksy", platform)
  };
};

export const createProcessingRecipe = async (url: string, platform: SourcePlatform): Promise<Recipe> => {
  const recipeId = createRecipeId(platform);
  const thumbnail = await enrichProcessingRecipe(url, platform);

  return createEmptyRecipe({
    id: recipeId,
    sourceUrl: url,
    sourcePlatform: platform,
    thumbnailUrl: thumbnail.thumbnailUrl,
    thumbnailSource: thumbnail.thumbnailSource,
    thumbnailFallbackStyle: thumbnail.thumbnailFallbackStyle
  });
};

export const completeRecipeProcessing = async (recipeId: string, result: ReconstructionResult): Promise<Recipe> => {
  return recipeRepository.update(recipeId, {
    sourceCreator: result.sourceCreator ?? null,
    sourceTitle: result.sourceTitle ?? null,
    status: "completed",
    title: result.title,
    description: result.description ?? null,
    servings: result.servings ?? null,
    prepTimeMinutes: result.prepTimeMinutes ?? null,
    cookTimeMinutes: result.cookTimeMinutes ?? null,
    totalTimeMinutes: result.totalTimeMinutes ?? null,
    ingredients: result.ingredients,
    steps: result.steps,
    thumbnailUrl: result.thumbnailUrl ?? null,
    thumbnailSource: result.thumbnailSource,
    thumbnailFallbackStyle: result.thumbnailFallbackStyle ?? null,
    confidenceScore: result.confidenceScore,
    inferredFields: result.inferredFields,
    missingFields: result.missingFields,
    validationWarnings: result.validationWarnings,
    rawExtraction: result.rawExtraction,
    isSynced: false
  });
};

export const failRecipeProcessing = async (recipeId: string, error: Error): Promise<Recipe> => {
  return recipeRepository.update(recipeId, {
    status: "failed",
    missingFields: [error.message],
    validationWarnings: [error.message]
  });
};

export const importRecipeFromUrl = async (
  url: string,
  options?: WorkflowCallbacks & {
    recipeId?: string;
  }
): Promise<Recipe> => {
  const platform = detectPlatformFromUrl(url);
  let processingRecipe = options?.recipeId ? await recipeRepository.getById(options.recipeId) : undefined;

  if (!processingRecipe) {
    processingRecipe = await createProcessingRecipe(url, platform);
    await recipeRepository.create(processingRecipe);
  }

  options?.onStageChange?.("queued", processingRecipe.id);

  try {
    options?.onStageChange?.("extracting", processingRecipe.id);
    const context = await extractRecipeContextFromUrl(url);
    await recipeRepository.update(processingRecipe.id, {
      rawExtraction: context,
      sourceCreator: context.creator ?? null,
      sourceTitle: context.title ?? null,
      thumbnailUrl: getThumbnailFromContext(context) ?? processingRecipe.thumbnailUrl ?? null
    });

    options?.onStageChange?.("identifying_ingredients", processingRecipe.id);
    const result = await reconstructRecipe(context);

    options?.onStageChange?.("building_steps", processingRecipe.id);
    const completed = await completeRecipeProcessing(processingRecipe.id, result);
    options?.onStageChange?.("completed", processingRecipe.id);
    return completed;
  } catch (error) {
    const typedError =
      error instanceof ExtractionFailedError || error instanceof RecipeReconstructionError || error instanceof Error
        ? error
        : new Error("Recipe import failed");
    const failed = await failRecipeProcessing(processingRecipe.id, typedError);
    options?.onStageChange?.("failed", processingRecipe.id);
    return failed;
  }
};

export const startRecipeImport = async (
  url: string,
  options?: WorkflowCallbacks
): Promise<{ processingRecipe: Recipe; completion: Promise<Recipe> }> => {
  const platform = detectPlatformFromUrl(url);
  const processingRecipe = await createProcessingRecipe(url, platform);
  await recipeRepository.create(processingRecipe);

  return {
    processingRecipe,
    completion: importRecipeFromUrl(url, {
      recipeId: processingRecipe.id,
      onStageChange: options?.onStageChange
    })
  };
};

