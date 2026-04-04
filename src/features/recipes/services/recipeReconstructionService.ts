import { RecipeReconstructionError } from "@/features/recipes/lib/errors";
import { aggregateSourceEvidence } from "@/features/recipes/lib/sourceEvidence";
import { generateFallbackThumbnailStyle, getThumbnailFromContext } from "@/features/recipes/services/thumbnailService";
import type {
  Ingredient,
  RawRecipeContext,
  Recipe,
  RecipeStep,
  ReconstructionResult,
  ThumbnailSource
} from "@/features/recipes/types";

type MetadataHints = {
  ingredientHints?: Record<string, unknown>[];
  stepHints?: Record<string, unknown>[];
  servingsHint?: number;
  prepTimeMinutesHint?: number;
  cookTimeMinutesHint?: number;
};

const readHints = (context: RawRecipeContext): MetadataHints => ((context.metadata ?? {}) as MetadataHints);

const buildId = (prefix: string, index: number) => `${prefix}-${index + 1}`;

export const extractIngredientsFromContext = async (context: RawRecipeContext): Promise<Ingredient[]> => {
  const hints = readHints(context);
  const hintedIngredients = hints.ingredientHints ?? [];

  if (hintedIngredients.length) {
    return hintedIngredients.map((ingredient, index) => ({
      id: buildId("ingredient", index),
      name: String(ingredient.name ?? "Ingredient"),
      quantity: typeof ingredient.quantity === "string" ? ingredient.quantity : ingredient.quantity == null ? null : String(ingredient.quantity),
      unit: typeof ingredient.unit === "string" ? ingredient.unit : ingredient.unit == null ? null : String(ingredient.unit),
      note: typeof ingredient.note === "string" ? ingredient.note : null,
      optional: Boolean(ingredient.optional),
      inferred: Boolean(ingredient.inferred)
    }));
  }

  const evidence = aggregateSourceEvidence(context);
  const ingredients: Ingredient[] = [];

  if (evidence.combinedText.includes("chicken")) {
    ingredients.push({ id: buildId("ingredient", ingredients.length), name: "Chicken", quantity: null, inferred: true });
  }
  if (evidence.combinedText.includes("garlic")) {
    ingredients.push({ id: buildId("ingredient", ingredients.length), name: "Garlic", quantity: null, inferred: true });
  }
  if (evidence.combinedText.includes("cream")) {
    ingredients.push({ id: buildId("ingredient", ingredients.length), name: "Cream", quantity: null, inferred: true });
  }
  if (evidence.combinedText.includes("salmon")) {
    ingredients.push({ id: buildId("ingredient", ingredients.length), name: "Salmon", quantity: null, inferred: true });
  }
  if (evidence.combinedText.includes("rice")) {
    ingredients.push({ id: buildId("ingredient", ingredients.length), name: "Rice", quantity: null, inferred: true });
  }

  return ingredients;
};

export const extractStepsFromContext = async (context: RawRecipeContext): Promise<RecipeStep[]> => {
  const hints = readHints(context);
  const stepHints = hints.stepHints ?? [];

  if (stepHints.length) {
    return stepHints.map((step, index) => ({
      id: buildId("step", index),
      order: index + 1,
      instruction: String(step.instruction ?? "Complete this cooking step."),
      durationMinutes:
        typeof step.durationMinutes === "number"
          ? step.durationMinutes
          : typeof step.duration_minutes === "number"
            ? step.duration_minutes
            : null,
      temperature: typeof step.temperature === "string" ? step.temperature : null,
      inferred: Boolean(step.inferred)
    }));
  }

  const evidence = aggregateSourceEvidence(context);

  if (evidence.cueMentions.length >= 2) {
    return [
      {
        id: "step-1",
        order: 1,
        instruction: "Prepare the main ingredients and start cooking the base elements from the original post.",
        inferred: true
      },
      {
        id: "step-2",
        order: 2,
        instruction: "Cook until the core ingredients are tender and the sauce or glaze comes together.",
        inferred: true
      }
    ];
  }

  return [
    {
      id: "step-1",
      order: 1,
      instruction: "Extracted recipe steps were incomplete, so Cooksy created a draft method.",
      inferred: true
    }
  ];
};

export const extractRecipeMetadata = async (context: RawRecipeContext) => {
  const hints = readHints(context);
  const evidence = aggregateSourceEvidence(context);
  const title = context.title?.trim() || `${context.platform} recipe import`;
  const description =
    context.caption?.trim() ||
    context.transcript?.slice(0, 160) ||
    (evidence.commentsText ? evidence.commentsText.slice(0, 160) : null) ||
    "Imported from social cooking content.";
  const servings = hints.servingsHint ?? null;
  const prepTimeMinutes = hints.prepTimeMinutesHint ?? null;
  const cookTimeMinutes = hints.cookTimeMinutesHint ?? null;

  return {
    title,
    description,
    servings,
    prepTimeMinutes,
    cookTimeMinutes,
    totalTimeMinutes:
      typeof prepTimeMinutes === "number" && typeof cookTimeMinutes === "number"
        ? prepTimeMinutes + cookTimeMinutes
        : null,
    sourceCreator: context.creator ?? null,
    sourceTitle: context.title ?? null
  };
};

export const inferMissingRecipeFields = async (
  partialRecipe: Omit<ReconstructionResult, "confidenceScore" | "validationWarnings" | "inferredFields" | "missingFields">,
  context: RawRecipeContext
) => {
  const inferredFields: string[] = [
    ...partialRecipe.ingredients
      .filter((ingredient) => ingredient.inferred)
      .map((ingredient) => `${ingredient.name} inferred from partial source cues`),
    ...partialRecipe.steps
      .filter((step) => step.inferred)
      .map((step) => `Step ${step.order} reconstructed from incomplete source detail`)
  ];
  const missingFields: string[] = [];

  const ingredients = partialRecipe.ingredients.map((ingredient) => {
    if (!ingredient.quantity) {
      const inferredQuantity =
        ingredient.name.toLowerCase().includes("garlic")
          ? "4"
          : null;

      if (!inferredQuantity) {
        missingFields.push(`${ingredient.name} quantity not provided`);
        return ingredient;
      }

      inferredFields.push(`${ingredient.name} quantity inferred`);
      return {
        ...ingredient,
        quantity: inferredQuantity,
        unit: ingredient.unit ?? (ingredient.name.toLowerCase().includes("garlic") ? "cloves" : ingredient.unit),
        inferred: true
      };
    }

    return ingredient;
  });

  const steps = partialRecipe.steps.map((step) => {
    if (!step.temperature && /roast|oven|bake/i.test(step.instruction)) {
      missingFields.push(`Temperature missing for step ${step.order}`);
    }

    if (!step.durationMinutes) {
      return step;
    }

    return step;
  });

  const servings =
    partialRecipe.servings ??
    (ingredients.length >= 5 ? 4 : 2);

  if (partialRecipe.servings == null) {
    inferredFields.push("Serving size inferred");
  }

  const evidence = aggregateSourceEvidence(context);
  const prepTimeMinutes = partialRecipe.prepTimeMinutes ?? (evidence.hasAnyTextSignals ? 12 : null);
  if (partialRecipe.prepTimeMinutes == null) {
    inferredFields.push("Prep time inferred");
  }

  const cookTimeMinutes = partialRecipe.cookTimeMinutes ?? (steps.some((step) => step.durationMinutes) ? steps.reduce((sum, step) => sum + (step.durationMinutes ?? 0), 0) : null);
  if (partialRecipe.cookTimeMinutes == null) {
    inferredFields.push("Cook time inferred");
  }

  const totalTimeMinutes =
    partialRecipe.totalTimeMinutes ??
    (typeof prepTimeMinutes === "number" && typeof cookTimeMinutes === "number" ? prepTimeMinutes + cookTimeMinutes : null);

  if (!evidence.hasAnyTextSignals) {
    missingFields.push("No transcript or caption available");
  }

  return {
    ...partialRecipe,
    ingredients,
    steps,
    servings,
    prepTimeMinutes,
    cookTimeMinutes,
    totalTimeMinutes,
    inferredFields,
    missingFields
  };
};

export const validateRecipe = (recipe: Omit<Recipe, "id" | "status" | "createdAt" | "updatedAt" | "isSynced">) => {
  const warnings: string[] = [];

  if (!recipe.title.trim()) {
    warnings.push("Recipe title is missing");
  }

  if (recipe.ingredients.length < 1) {
    warnings.push("Recipe needs at least one ingredient");
  }

  if (recipe.steps.length < 1) {
    warnings.push("Recipe needs at least one step");
  }

  recipe.steps.forEach((step, index) => {
    if (step.order !== index + 1) {
      warnings.push("Recipe steps must stay in sequential order");
    }
  });

  const quantifiedIngredients = recipe.ingredients.filter((ingredient) => ingredient.quantity);
  if (recipe.ingredients.length && quantifiedIngredients.length / recipe.ingredients.length < 0.5) {
    warnings.push("More than half of the ingredients are missing explicit quantities");
  }

  if (typeof recipe.servings === "number" && (recipe.servings < 1 || recipe.servings > 12)) {
    warnings.push("Serving size looks implausible");
  }

  if (typeof recipe.totalTimeMinutes === "number" && recipe.totalTimeMinutes > 300) {
    warnings.push("Total cook time looks unusually long");
  }

  if (!recipe.steps.some((step) => /garlic|cream|stock|pasta|salmon|chicken/i.test(step.instruction))) {
    warnings.push("Steps do not reference many of the detected cooking cues");
  }

  return warnings;
};

export const scoreRecipeConfidence = (
  recipe: Omit<Recipe, "id" | "status" | "createdAt" | "updatedAt" | "isSynced">,
  context: RawRecipeContext
) => {
  const evidence = aggregateSourceEvidence(context);
  let score = 25;

  if (evidence.hasStrongTranscript) {
    score += 24;
  } else if (evidence.captionText) {
    score += 10;
  }

  if (recipe.sourceTitle) {
    score += 10;
  }

  if (recipe.sourceCreator) {
    score += 6;
  }

  if (recipe.thumbnailUrl) {
    score += 5;
  }

  score += Math.min(evidence.explicitQuantityMentions * 3, 15);
  score += Math.min(evidence.cueMentions.length * 2, 10);
  score += Math.min(evidence.signalOriginCount * 2, 6);
  score += evidence.ocrText ? 6 : 0;
  score += evidence.commentsText ? 4 : 0;
  score += evidence.cueMentions.length >= 3 ? 6 : 0;

  const explicitQuantityRatio = recipe.ingredients.length
    ? recipe.ingredients.filter((ingredient) => ingredient.quantity).length / recipe.ingredients.length
    : 0;
  score += Math.round(explicitQuantityRatio * 20);

  if (recipe.steps.length >= 3) {
    score += 10;
  }

  score -= Math.min(recipe.inferredFields.length * 4, 20);
  score -= Math.min(recipe.missingFields.length * 5, 20);
  score -= Math.min(recipe.validationWarnings.length * 6, 24);

  return Math.max(0, Math.min(100, score));
};

export const reconstructRecipe = async (context: RawRecipeContext): Promise<ReconstructionResult> => {
  const ingredients = await extractIngredientsFromContext(context);
  const steps = await extractStepsFromContext(context);
  const metadata = await extractRecipeMetadata(context);

  if (ingredients.length < 1 || steps.length < 1) {
    throw new RecipeReconstructionError();
  }

  const thumbnailUrl = getThumbnailFromContext(context);
  const thumbnailSource = (context.platform ?? "generated") as ThumbnailSource;
  const thumbnailFallbackStyle = generateFallbackThumbnailStyle(metadata.title, context.platform);

  const inferred = await inferMissingRecipeFields(
    {
      title: metadata.title,
      description: metadata.description,
      servings: metadata.servings,
      prepTimeMinutes: metadata.prepTimeMinutes,
      cookTimeMinutes: metadata.cookTimeMinutes,
      totalTimeMinutes: metadata.totalTimeMinutes,
      ingredients,
      steps,
      thumbnailUrl,
      thumbnailSource,
      thumbnailFallbackStyle,
      sourceCreator: metadata.sourceCreator,
      sourceTitle: metadata.sourceTitle,
      rawExtraction: context
    },
    context
  );

  const validationWarnings = validateRecipe({
    sourceUrl: context.sourceUrl,
    sourcePlatform: context.platform,
    sourceCreator: inferred.sourceCreator,
    sourceTitle: inferred.sourceTitle,
    title: inferred.title,
    description: inferred.description,
    servings: inferred.servings,
    prepTimeMinutes: inferred.prepTimeMinutes,
    cookTimeMinutes: inferred.cookTimeMinutes,
    totalTimeMinutes: inferred.totalTimeMinutes,
    ingredients: inferred.ingredients,
    steps: inferred.steps,
    thumbnailUrl: inferred.thumbnailUrl,
    thumbnailSource: inferred.thumbnailSource,
    thumbnailFallbackStyle: inferred.thumbnailFallbackStyle,
    confidenceScore: 0,
    inferredFields: inferred.inferredFields,
    missingFields: inferred.missingFields,
    validationWarnings: [],
    rawExtraction: context
  });

  const confidenceScore = scoreRecipeConfidence(
    {
      sourceUrl: context.sourceUrl,
      sourcePlatform: context.platform,
      sourceCreator: inferred.sourceCreator,
      sourceTitle: inferred.sourceTitle,
      title: inferred.title,
      description: inferred.description,
      servings: inferred.servings,
      prepTimeMinutes: inferred.prepTimeMinutes,
      cookTimeMinutes: inferred.cookTimeMinutes,
      totalTimeMinutes: inferred.totalTimeMinutes,
      ingredients: inferred.ingredients,
      steps: inferred.steps,
      thumbnailUrl: inferred.thumbnailUrl,
      thumbnailSource: inferred.thumbnailSource,
      thumbnailFallbackStyle: inferred.thumbnailFallbackStyle,
      confidenceScore: 0,
      inferredFields: inferred.inferredFields,
      missingFields: inferred.missingFields,
      validationWarnings,
      rawExtraction: context
    },
    context
  );

  return {
    title: inferred.title,
    description: inferred.description,
    servings: inferred.servings,
    prepTimeMinutes: inferred.prepTimeMinutes,
    cookTimeMinutes: inferred.cookTimeMinutes,
    totalTimeMinutes: inferred.totalTimeMinutes,
    ingredients: inferred.ingredients,
    steps: inferred.steps,
    thumbnailUrl: inferred.thumbnailUrl,
    thumbnailSource: inferred.thumbnailSource,
    thumbnailFallbackStyle: inferred.thumbnailFallbackStyle,
    sourceCreator: inferred.sourceCreator,
    sourceTitle: inferred.sourceTitle,
    confidenceScore,
    inferredFields: inferred.inferredFields,
    missingFields: inferred.missingFields,
    validationWarnings,
    rawExtraction: context
  };
};
