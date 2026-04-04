import type { Recipe as DomainRecipe } from "@/features/recipes/types";
import type { Recipe as UiRecipe } from "@/types/recipe";

const combineIngredientQuantity = (recipeIngredient: DomainRecipe["ingredients"][number]) =>
  [recipeIngredient.quantity, recipeIngredient.unit].filter(Boolean).join(" ").trim() || recipeIngredient.note || "To taste";

const confidenceLevel = (score: number): UiRecipe["confidence"] =>
  score >= 85 ? "high" : score >= 60 ? "medium" : "low";

export const mapDomainRecipeToUiRecipe = (recipe: DomainRecipe): UiRecipe => ({
  id: recipe.id,
  status: recipe.status === "completed" ? "ready" : recipe.status,
  importJobId: recipe.id,
  processingMessage:
    recipe.status === "processing"
      ? "Generating recipe..."
      : recipe.status === "failed"
        ? recipe.validationWarnings[0] ?? recipe.missingFields[0] ?? "Recipe generation failed"
        : undefined,
  title: recipe.title,
  description:
    recipe.description ??
    "Cooksy reconstructed this recipe from the original social cooking post so you can save and edit it later.",
  heroNote:
    recipe.status === "processing"
      ? "Saved from a link you discovered. Cooksy is turning it into something you can actually cook."
      : recipe.sourceTitle ?? recipe.description ?? "Imported from social media and reconstructed for home cooking.",
  imageLabel: `${recipe.title} cover`,
  thumbnailUrl: recipe.thumbnailUrl ?? null,
  thumbnailSource: recipe.thumbnailSource,
  thumbnailFallbackStyle: recipe.thumbnailFallbackStyle ?? undefined,
  servings: recipe.servings ?? 2,
  prepTimeMinutes: recipe.prepTimeMinutes ?? 0,
  cookTimeMinutes: recipe.cookTimeMinutes ?? 0,
  totalTimeMinutes: recipe.totalTimeMinutes ?? 0,
  confidence: confidenceLevel(recipe.confidenceScore),
  confidenceScore: recipe.confidenceScore,
  confidenceNote:
    recipe.validationWarnings[0] ??
    (recipe.inferredFields.length
      ? `${recipe.inferredFields[0]}.`
      : "Cooksy reconstructed this recipe from available source signals."),
  inferredFields: recipe.inferredFields,
  missingFields: recipe.missingFields,
  isSaved: true,
  source: {
    creator: recipe.sourceCreator ?? "Imported Creator",
    url: recipe.sourceUrl,
    platform: recipe.sourcePlatform
  },
  ingredients: recipe.ingredients.map((ingredient) => ({
    id: ingredient.id,
    name: ingredient.name,
    quantity: combineIngredientQuantity(ingredient),
    optional: ingredient.optional
  })),
  steps: recipe.steps.map((step) => ({
    id: step.id,
    title: `Step ${step.order}`,
    instruction: step.instruction,
    durationMinutes: step.durationMinutes ?? undefined
  })),
  tags: [
    "Imported",
    recipe.sourcePlatform === "youtube" ? "Video" : recipe.sourcePlatform === "tiktok" ? "Short Form" : "Social Save"
  ]
});

