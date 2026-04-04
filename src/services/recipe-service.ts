import { hasSupabaseConfig } from "@/lib/env";
import { supabase } from "@/lib/supabase";
import { mockBooks, mockRecipes } from "@/mocks/recipes";
import { importRecipeFromUrl as runImportRecipe } from "@/services/import-service";
import type { ImportProgress, Recipe, RecipeBook } from "@/types/recipe";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const mapRemoteRecipe = (row: any): Recipe => ({
  id: row.id,
  status: row.status ?? "ready",
  importJobId: row.import_job_id ?? undefined,
  processingMessage: row.status === "processing" ? "Generating recipe..." : undefined,
  title: row.title,
  description: row.description,
  heroNote: row.hero_note,
  imageLabel: row.image_label ?? "Recipe cover",
  thumbnailUrl: row.thumbnail_url ?? null,
  thumbnailSource: row.thumbnail_source ?? "generated",
  thumbnailFallbackStyle: row.thumbnail_fallback_style ?? undefined,
  servings: row.servings,
  prepTimeMinutes: row.prep_time_minutes,
  cookTimeMinutes: row.cook_time_minutes,
  totalTimeMinutes: row.total_time_minutes,
  confidence: row.confidence,
  confidenceScore: row.confidence_score ?? 0,
  confidenceNote: row.confidence_note,
  inferredFields: row.inferred_fields ?? [],
  missingFields: row.missing_fields ?? [],
  isSaved: true,
  source: {
    creator: row.source_creator,
    url: row.source_url,
    platform: row.source_platform
  },
  ingredients: (row.recipe_ingredients ?? [])
    .sort((a: any, b: any) => a.position - b.position)
    .map((ingredient: any) => ({
      id: ingredient.id,
      name: ingredient.name,
      quantity: ingredient.quantity,
      optional: ingredient.optional
    })),
  steps: (row.recipe_steps ?? [])
    .sort((a: any, b: any) => a.position - b.position)
    .map((step: any) => ({
      id: step.id,
      title: step.title,
      instruction: step.instruction,
      durationMinutes: step.duration_minutes ?? undefined
    })),
  tags: row.tags ?? []
});

export const fetchRecentRecipes = async (): Promise<Recipe[]> => {
  if (hasSupabaseConfig && supabase) {
    const { data, error } = await supabase
      .from("recipes")
      .select(
        `
          id,
          import_job_id,
          status,
          title,
          description,
          hero_note,
          image_label,
          thumbnail_url,
          thumbnail_source,
          thumbnail_fallback_style,
          servings,
          prep_time_minutes,
          cook_time_minutes,
          total_time_minutes,
          confidence,
          confidence_score,
          confidence_note,
          inferred_fields,
          missing_fields,
          source_creator,
          source_url,
          source_platform,
          tags,
          recipe_ingredients (
            id,
            position,
            name,
            quantity,
            optional
          ),
          recipe_steps (
            id,
            position,
            title,
            instruction,
            duration_minutes
          )
        `
      )
      .order("created_at", { ascending: false })
      .limit(12);

    if (!error && data) {
      return data.map(mapRemoteRecipe);
    }
  }

  await sleep(120);
  return mockRecipes;
};

export const fetchRecipeById = async (recipeId: string): Promise<Recipe | undefined> => {
  await sleep(120);
  return mockRecipes.find((recipe) => recipe.id === recipeId);
};

export const fetchRecipeBooks = async (): Promise<RecipeBook[]> => {
  await sleep(120);
  return mockBooks;
};

export const importRecipeFromUrl = async (
  url: string,
  onProgress?: (progress: ImportProgress) => void
): Promise<Recipe> => runImportRecipe(url, onProgress);
