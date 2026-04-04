import { RecipeReconstructionError } from "@/features/recipes/lib/errors";
import { aggregateEvidence, aggregateSourceEvidence, hydrateEvidenceContext } from "@/features/recipes/lib/sourceEvidence";
import { generateFallbackThumbnailStyle, getThumbnailFromContext, selectBestThumbnailCandidate } from "@/features/recipes/services/thumbnailService";
import type {
  ConfidenceReport,
  Ingredient,
  RawRecipeContext,
  Recipe,
  RecipeStep,
  ReconstructionResult,
  ThumbnailSource
} from "@/features/recipes/types";

type PartialRecipe = Omit<
  ReconstructionResult,
  "confidenceScore" | "confidenceReport" | "validationWarnings" | "inferredFields" | "missingFields"
>;

const buildId = (prefix: string, index: number) => `${prefix}-${index + 1}`;

const toTitleCase = (value: string) => value.replace(/\b\w/g, (char) => char.toUpperCase());

const normalizeInstruction = (value: string) => {
  const normalized = value.replace(/\s+/g, " ").trim();
  if (!normalized) {
    return "";
  }

  const withCapital = normalized.charAt(0).toUpperCase() + normalized.slice(1);
  return /[.!?]$/.test(withCapital) ? withCapital : `${withCapital}.`;
};

const ensureInstructionObject = (instruction: string, fallbackObject?: string | null) => {
  if (fallbackObject && !new RegExp(`\\b${fallbackObject.toLowerCase()}\\b`, "i").test(instruction)) {
    return normalizeInstruction(`${instruction.replace(/[.!?]$/, "")} with ${fallbackObject.toLowerCase()}`);
  }

  return normalizeInstruction(instruction);
};

const extractIngredientsFromAggregatedEvidence = async (context: RawRecipeContext): Promise<Ingredient[]> => {
  const aggregated = aggregateEvidence(context);

  return aggregated.ingredients.map((ingredient, index) => ({
    id: ingredient.id || buildId("ingredient", index),
    name: toTitleCase(ingredient.name),
    quantity: ingredient.quantity ?? null,
    unit: ingredient.unit ?? null,
    note: ingredient.note ?? null,
    inferred: Boolean(ingredient.uncertain)
  }));
};

export const extractIngredientsFromContext = async (context: RawRecipeContext): Promise<Ingredient[]> =>
  extractIngredientsFromAggregatedEvidence(context);

export const extractStepsFromContext = async (context: RawRecipeContext): Promise<RecipeStep[]> => {
  const aggregated = aggregateEvidence(context);
  const uniqueInstructions = new Set<string>();

  return aggregated.steps
    .map((step, index) => ({
      ...step,
      instruction: ensureInstructionObject(step.instruction, step.object)
    }))
    .filter((step) => {
      const key = step.instruction.toLowerCase();
      if (uniqueInstructions.has(key)) {
        return false;
      }

      uniqueInstructions.add(key);
      return true;
    })
    .map((step, index) => ({
      id: step.id || buildId("step", index),
      order: index + 1,
      instruction: step.instruction,
      durationMinutes: step.durationMinutes ?? null,
      temperature: null,
      inferred: Boolean(step.uncertain)
    }));
};

export const extractRecipeMetadata = async (context: RawRecipeContext) => {
  const aggregated = aggregateEvidence(context);
  const evidence = aggregateSourceEvidence(context);
  const topTitle = aggregated.metadata.titleCandidates[0]?.value ?? context.title?.trim() ?? `${context.platform} recipe import`;
  const sourceCreator = aggregated.metadata.creatorCandidates[0]?.value ?? context.creator?.trim() ?? null;
  const description =
    context.caption?.trim() ||
    context.transcript?.slice(0, 180) ||
    (evidence.commentsText ? evidence.commentsText.slice(0, 180) : null) ||
    "Imported from social cooking content.";

  return {
    title: topTitle,
    description,
    servings: aggregated.metadata.servings?.value ?? null,
    prepTimeMinutes: aggregated.metadata.prepTimeMinutes?.value ?? null,
    cookTimeMinutes: aggregated.metadata.cookTimeMinutes?.value ?? null,
    totalTimeMinutes: aggregated.metadata.totalTimeMinutes?.value ?? null,
    sourceCreator,
    sourceTitle: context.title ?? topTitle
  };
};

export const inferMissingRecipeFields = async (partialRecipe: PartialRecipe, context: RawRecipeContext) => {
  const evidence = aggregateSourceEvidence(context);
  const inferredFields: string[] = [];
  const missingFields: string[] = [];

  const ingredients = partialRecipe.ingredients.map((ingredient) => {
    if (ingredient.quantity) {
      return ingredient;
    }

    if (/garlic/i.test(ingredient.name)) {
      inferredFields.push(`${ingredient.name} quantity inferred`);
      return {
        ...ingredient,
        quantity: "4",
        unit: ingredient.unit ?? "cloves",
        inferred: true
      };
    }

    missingFields.push(`${ingredient.name} quantity not provided`);
    return ingredient;
  });

  const steps = partialRecipe.steps.map((step) => {
    const nextStep = { ...step };
    if (!nextStep.durationMinutes && /simmer|roast|bake|cook/i.test(nextStep.instruction)) {
      nextStep.durationMinutes = /simmer/i.test(nextStep.instruction) ? 12 : /roast|bake/i.test(nextStep.instruction) ? 15 : 8;
      nextStep.inferred = true;
      inferredFields.push(`Timing inferred for step ${step.order}`);
    }

    if (!nextStep.temperature && /oven|bake|roast/i.test(nextStep.instruction)) {
      missingFields.push(`Temperature missing for step ${step.order}`);
    }

    return nextStep;
  });

  const servings = partialRecipe.servings ?? (ingredients.length >= 5 ? 4 : ingredients.length >= 3 ? 2 : null);
  if (partialRecipe.servings == null && servings != null) {
    inferredFields.push("Serving size inferred");
  }

  const prepTimeMinutes = partialRecipe.prepTimeMinutes ?? (evidence.hasAnyTextSignals ? 12 : null);
  if (partialRecipe.prepTimeMinutes == null && prepTimeMinutes != null) {
    inferredFields.push("Prep time inferred");
  }

  const cookTimeMinutes =
    partialRecipe.cookTimeMinutes ??
    (steps.length ? steps.reduce((sum, step) => sum + (step.durationMinutes ?? 0), 0) || null : null);
  if (partialRecipe.cookTimeMinutes == null && cookTimeMinutes != null) {
    inferredFields.push("Cook time inferred");
  }

  const totalTimeMinutes =
    partialRecipe.totalTimeMinutes ??
    (typeof prepTimeMinutes === "number" && typeof cookTimeMinutes === "number" ? prepTimeMinutes + cookTimeMinutes : null);

  if (!evidence.hasAnyTextSignals) {
    missingFields.push("Very little source text was available");
  }

  return {
    ...partialRecipe,
    ingredients,
    steps,
    servings,
    prepTimeMinutes,
    cookTimeMinutes,
    totalTimeMinutes,
    inferredFields: Array.from(new Set(inferredFields)),
    missingFields: Array.from(new Set(missingFields))
  };
};

export const validateRecipe = (recipe: Omit<Recipe, "id" | "status" | "createdAt" | "updatedAt" | "isSynced" | "confidenceReport">) => {
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

    if (!step.instruction.trim()) {
      warnings.push(`Step ${index + 1} has no usable instruction`);
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

  if (!recipe.steps.every((step) => /add|bake|boil|coat|cook|finish|fold|mix|pour|roast|season|sear|serve|simmer|stir|whisk/i.test(step.instruction))) {
    warnings.push("Some steps are still vague and may need review");
  }

  return Array.from(new Set(warnings));
};

export const scoreRecipeConfidence = (
  recipe: Omit<Recipe, "id" | "status" | "createdAt" | "updatedAt" | "isSynced">,
  context: RawRecipeContext
): ConfidenceReport => {
  const evidence = aggregateSourceEvidence(context);
  const aggregated = aggregateEvidence(context);
  const warnings: string[] = [];
  const lowConfidenceAreas: string[] = [];
  const missingFields = [...recipe.missingFields];

  const transcriptStrength = evidence.hasStrongTranscript ? 0.18 : evidence.hasAnyTextSignals ? 0.08 : 0;
  const metadataStrength = recipe.sourceTitle ? 0.05 : 0;
  const creatorStrength = recipe.sourceCreator ? 0.03 : 0;
  const thumbnailStrength = recipe.thumbnailUrl ? 0.03 : 0;
  const ingredientAgreement = aggregated.ingredients.length
    ? aggregated.ingredients.reduce((sum, ingredient) => sum + ingredient.confidence, 0) / aggregated.ingredients.length
    : 0;
  const stepClarity = aggregated.steps.length
    ? aggregated.steps.reduce((sum, step) => sum + step.confidence + (step.actionVerb ? 0.08 : 0), 0) / aggregated.steps.length
    : 0;
  const ingredientStrength = ingredientAgreement * 0.14;
  const stepStrength = Math.min(0.18, stepClarity * 0.16);
  const explicitQuantityCoverage = recipe.ingredients.length
    ? recipe.ingredients.filter((ingredient) => ingredient.quantity).length / recipe.ingredients.length
    : 0;
  const explicitQuantityStrength = explicitQuantityCoverage * 0.1;
  const signalRichness = Math.min(0.08, evidence.signalOriginCount * 0.02 + evidence.actionVerbCount * 0.01);
  const recoveryStrength =
    aggregated.ingredients.length >= 3 && aggregated.steps.length >= 2 && (evidence.ocrText || evidence.commentsText) ? 0.08 : 0;

  const lowQualityPenalty = Math.min(0.08, evidence.lowQualitySignalCount * 0.02);
  const missingPenalty = Math.min(0.12, missingFields.length * 0.02);
  const inferredPenalty = Math.min(0.08, recipe.inferredFields.length * 0.01);
  const validationPenalty = Math.min(0.12, recipe.validationWarnings.length * 0.02);

  recipe.validationWarnings.forEach((warning) => {
    warnings.push(warning);
  });

  aggregated.ingredients.forEach((ingredient) => {
    if (ingredient.confidence < 0.56 || ingredient.uncertain) {
      lowConfidenceAreas.push(`Ingredient: ${ingredient.name}`);
    }
  });

  aggregated.steps.forEach((step, index) => {
    if (step.confidence < 0.6 || !step.actionVerb || !step.object) {
      lowConfidenceAreas.push(`Step ${index + 1}`);
    }
  });

  if (evidence.lowQualitySignalCount > 0) {
    warnings.push("Some recipe details came from lower-confidence sources like OCR or comments");
  }

  if (!recipe.sourceCreator) {
    lowConfidenceAreas.push("Source creator");
  }

  if (!recipe.thumbnailUrl) {
    lowConfidenceAreas.push("Recipe cover");
  }

  const score = Math.max(
    0,
    Math.min(
      1,
      0.18 +
        transcriptStrength +
        metadataStrength +
        creatorStrength +
        thumbnailStrength +
        ingredientStrength +
        stepStrength +
        signalRichness +
        explicitQuantityStrength +
        recoveryStrength -
        lowQualityPenalty -
        missingPenalty -
        inferredPenalty -
        validationPenalty
    )
  );

  return {
    score,
    warnings: Array.from(new Set(warnings)),
    missingFields: Array.from(new Set(missingFields)),
    lowConfidenceAreas: Array.from(new Set(lowConfidenceAreas))
  };
};

export const reconstructRecipe = async (context: RawRecipeContext): Promise<ReconstructionResult> => {
  const hydratedContext = hydrateEvidenceContext(context);
  const ingredients = await extractIngredientsFromContext(hydratedContext);
  const steps = await extractStepsFromContext(hydratedContext);
  const metadata = await extractRecipeMetadata(hydratedContext);

  if (ingredients.length < 1 || steps.length < 1) {
    throw new RecipeReconstructionError();
  }

  const thumbnailUrl =
    selectBestThumbnailCandidate(hydratedContext.thumbnailCandidates ?? [], hydratedContext.platform) ??
    getThumbnailFromContext(hydratedContext);
  const thumbnailSource = (hydratedContext.platform ?? "generated") as ThumbnailSource;
  const thumbnailFallbackStyle = generateFallbackThumbnailStyle(metadata.title, hydratedContext.platform);

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
      rawExtraction: hydratedContext
    },
    hydratedContext
  );

  const validationWarnings = validateRecipe({
    sourceUrl: hydratedContext.sourceUrl,
    sourcePlatform: hydratedContext.platform,
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
    rawExtraction: hydratedContext
  });

  const confidenceReport = scoreRecipeConfidence(
    {
      sourceUrl: hydratedContext.sourceUrl,
      sourcePlatform: hydratedContext.platform,
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
      confidenceReport: {
        score: 0,
        warnings: [],
        missingFields: [],
        lowConfidenceAreas: []
      },
      inferredFields: inferred.inferredFields,
      missingFields: inferred.missingFields,
      validationWarnings,
      rawExtraction: hydratedContext
    },
    hydratedContext
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
    confidenceScore: Math.round(confidenceReport.score * 100),
    confidenceReport,
    inferredFields: inferred.inferredFields,
    missingFields: confidenceReport.missingFields,
    validationWarnings: Array.from(new Set([...validationWarnings, ...confidenceReport.warnings])),
    rawExtraction: hydratedContext
  };
};
