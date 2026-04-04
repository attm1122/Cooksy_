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

const mapRemoteBook = (row: any): RecipeBook => ({
  id: row.id,
  name: row.name,
  description: row.description,
  coverTone: row.cover_tone,
  recipeIds: (row.recipe_book_items ?? []).map((item: any) => item.recipe_id)
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
  if (hasSupabaseConfig && supabase) {
    const { data, error } = await supabase
      .from("recipe_books")
      .select(
        `
          id,
          name,
          description,
          cover_tone,
          recipe_book_items (
            recipe_id
          )
        `
      )
      .order("created_at", { ascending: false });

    if (!error && data) {
      return data.map(mapRemoteBook);
    }
  }

  await sleep(120);
  return mockBooks;
};

export const importRecipeFromUrl = async (
  url: string,
  onProgress?: (progress: ImportProgress) => void
): Promise<Recipe> => runImportRecipe(url, onProgress);

export const updateRecipeInBackend = async (recipe: Recipe): Promise<Recipe> => {
  if (hasSupabaseConfig && supabase) {
    const { error: recipeError } = await supabase
      .from("recipes")
      .update({
        status: recipe.status,
        title: recipe.title,
        description: recipe.description,
        hero_note: recipe.heroNote,
        image_label: recipe.imageLabel,
        thumbnail_url: recipe.thumbnailUrl,
        thumbnail_source: recipe.thumbnailSource,
        thumbnail_fallback_style: recipe.thumbnailFallbackStyle ?? null,
        servings: recipe.servings,
        prep_time_minutes: recipe.prepTimeMinutes,
        cook_time_minutes: recipe.cookTimeMinutes,
        total_time_minutes: recipe.totalTimeMinutes,
        confidence: recipe.confidence,
        confidence_score: recipe.confidenceScore,
        confidence_note: recipe.confidenceNote,
        inferred_fields: recipe.inferredFields,
        missing_fields: recipe.missingFields,
        source_creator: recipe.source.creator,
        source_url: recipe.source.url,
        source_platform: recipe.source.platform,
        tags: recipe.tags
      })
      .eq("id", recipe.id);

    if (!recipeError) {
      await supabase.from("recipe_ingredients").delete().eq("recipe_id", recipe.id);
      await supabase.from("recipe_steps").delete().eq("recipe_id", recipe.id);

      if (recipe.ingredients.length) {
        await supabase.from("recipe_ingredients").insert(
          recipe.ingredients.map((ingredient, index) => ({
            recipe_id: recipe.id,
            position: index,
            name: ingredient.name,
            quantity: ingredient.quantity,
            optional: Boolean(ingredient.optional)
          }))
        );
      }

      if (recipe.steps.length) {
        await supabase.from("recipe_steps").insert(
          recipe.steps.map((step, index) => ({
            recipe_id: recipe.id,
            position: index,
            title: step.title,
            instruction: step.instruction,
            duration_minutes: step.durationMinutes ?? null
          }))
        );
      }
    }
  }

  return recipe;
};

export const createRecipeBookInBackend = async (input: Pick<RecipeBook, "name" | "description" | "coverTone">): Promise<RecipeBook> => {
  if (hasSupabaseConfig && supabase) {
    const { data, error } = await supabase
      .from("recipe_books")
      .insert({
        name: input.name,
        description: input.description,
        cover_tone: input.coverTone
      })
      .select("id, name, description, cover_tone")
      .single();

    if (!error && data) {
      return {
        id: data.id,
        name: data.name,
        description: data.description,
        coverTone: data.cover_tone,
        recipeIds: []
      };
    }
  }

  return {
    id: `local-book-${Date.now()}`,
    name: input.name,
    description: input.description,
    coverTone: input.coverTone,
    recipeIds: []
  };
};

export const addRecipeToBookInBackend = async (recipeId: string, bookId: string): Promise<void> => {
  if (hasSupabaseConfig && supabase) {
    await supabase.from("recipe_book_items").upsert(
      {
        book_id: bookId,
        recipe_id: recipeId
      },
      { onConflict: "book_id,recipe_id" }
    );
  }
};

export const removeRecipeFromBookInBackend = async (recipeId: string, bookId: string): Promise<void> => {
  if (hasSupabaseConfig && supabase) {
    await supabase.from("recipe_book_items").delete().eq("book_id", bookId).eq("recipe_id", recipeId);
  }
};
