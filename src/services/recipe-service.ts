import { appEnv, hasSupabaseConfig } from "@/lib/env";
import { trackEvent } from "@/lib/analytics";
import { captureError } from "@/lib/monitoring";
import { supabase } from "@/lib/supabase";
import { mockBooks, mockRecipes } from "@/mocks/recipes";
import {
  beginRecipeImport as runBeginRecipeImport,
  importRecipeFromUrl as runImportRecipe,
  pollImportJobUntilComplete as runPollImportJobUntilComplete,
  retryRecipeImport as runRetryRecipeImport
} from "@/services/import-service";
import type { ImportProgress, Recipe, RecipeBook } from "@/types/recipe";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
const shouldUseSeedData = appEnv.recipeImportMode === "mock" || !hasSupabaseConfig;

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
  confidenceReport: {
    score: Math.max(0, Math.min(1, (row.confidence_score ?? 0) / 100)),
    warnings: [],
    missingFields: row.missing_fields ?? [],
    lowConfidenceAreas: []
  },
  inferredFields: row.inferred_fields ?? [],
  missingFields: row.missing_fields ?? [],
  warnings: [],
  editableFields: row.missing_fields ?? [],
  rawExtraction: row.raw_extraction ?? undefined,
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

const getCurrentUserId = async () => {
  if (!supabase) {
    return undefined;
  }

  const { data, error } = await supabase.auth.getUser();

  if (error) {
    captureError(error, {
      action: "get_current_user_id"
    });
    throw error;
  }

  return data.user?.id;
};

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
          raw_extraction,
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
      trackEvent("recipes_hydrated", {
        count: data.length,
        source: "supabase"
      });
      return data.map(mapRemoteRecipe);
    }

    if (error) {
      captureError(error, {
        action: "fetch_recent_recipes"
      });
      throw error;
    }
  }

  if (shouldUseSeedData) {
    await sleep(120);
    trackEvent("recipes_hydrated", {
      count: mockRecipes.length,
      source: "mock"
    });
    return mockRecipes;
  }

  return [];
};

export const fetchRecipeById = async (recipeId: string): Promise<Recipe | undefined> => {
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
          raw_extraction,
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
      .eq("id", recipeId)
      .maybeSingle();

    if (!error && data) {
      return mapRemoteRecipe(data);
    }

    if (error) {
      captureError(error, {
        action: "fetch_recipe_by_id",
        recipeId
      });
      throw error;
    }
  }

  if (shouldUseSeedData) {
    await sleep(120);
    return mockRecipes.find((recipe) => recipe.id === recipeId);
  }

  return undefined;
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
      trackEvent("books_hydrated", {
        count: data.length,
        source: "supabase"
      });
      return data.map(mapRemoteBook);
    }

    if (error) {
      captureError(error, {
        action: "fetch_recipe_books"
      });
      throw error;
    }
  }

  if (shouldUseSeedData) {
    await sleep(120);
    trackEvent("books_hydrated", {
      count: mockBooks.length,
      source: "mock"
    });
    return mockBooks;
  }

  return [];
};

export const beginRecipeImport = async (url: string) => runBeginRecipeImport(url);

export const importRecipeFromUrl = async (
  url: string,
  onProgress?: (progress: ImportProgress) => void
): Promise<Recipe> => runImportRecipe(url, onProgress);

export const pollImportJobUntilComplete = async (
  jobId: string,
  onProgress?: (progress: ImportProgress) => void
): Promise<Recipe> => runPollImportJobUntilComplete(jobId, onProgress);

export const retryRecipeImport = async (
  recipe: Pick<Recipe, "id" | "source">,
  onProgress?: (progress: ImportProgress) => void
) => runRetryRecipeImport(recipe, onProgress);

export const updateRecipeInBackend = async (recipe: Recipe): Promise<Recipe> => {
  if (hasSupabaseConfig && supabase) {
    const { error } = await supabase.rpc("save_recipe_graph", {
      p_recipe_id: recipe.id,
      p_user_id: null,
      p_import_job_id: recipe.importJobId ?? null,
      p_status: recipe.status,
      p_title: recipe.title,
      p_description: recipe.description,
      p_hero_note: recipe.heroNote,
      p_image_label: recipe.imageLabel,
      p_thumbnail_url: recipe.thumbnailUrl,
      p_thumbnail_source: recipe.thumbnailSource,
      p_thumbnail_fallback_style: recipe.thumbnailFallbackStyle ?? null,
      p_servings: recipe.servings,
      p_prep_time_minutes: recipe.prepTimeMinutes,
      p_cook_time_minutes: recipe.cookTimeMinutes,
      p_total_time_minutes: recipe.totalTimeMinutes,
      p_confidence: recipe.confidence,
      p_confidence_score: recipe.confidenceScore,
      p_confidence_note: recipe.confidenceNote,
      p_inferred_fields: recipe.inferredFields,
      p_missing_fields: recipe.missingFields,
      p_raw_extraction: recipe.rawExtraction ?? null,
      p_source_creator: recipe.source.creator,
      p_source_url: recipe.source.url,
      p_source_platform: recipe.source.platform,
      p_tags: recipe.tags,
      p_ingredients: recipe.ingredients.map((ingredient) => ({
        name: ingredient.name,
        quantity: ingredient.quantity,
        optional: Boolean(ingredient.optional)
      })),
      p_steps: recipe.steps.map((step) => ({
        title: step.title,
        instruction: step.instruction,
        duration_minutes: step.durationMinutes ?? null
      }))
    });

    if (!error) {
      trackEvent("recipe_updated", {
        recipeId: recipe.id,
        status: recipe.status
      });
    } else {
      captureError(error, {
        action: "update_recipe",
        recipeId: recipe.id
      });
      throw error;
    }
  }

  return recipe;
};

export const createRecipeBookInBackend = async (input: Pick<RecipeBook, "name" | "description" | "coverTone">): Promise<RecipeBook> => {
  if (hasSupabaseConfig && supabase) {
    const userId = await getCurrentUserId();
    const { data, error } = await supabase
      .from("recipe_books")
      .insert({
        user_id: userId,
        name: input.name,
        description: input.description,
        cover_tone: input.coverTone
      })
      .select("id, name, description, cover_tone")
      .single();

    if (!error && data) {
      trackEvent("recipe_book_created", {
        bookId: data.id
      });
      return {
        id: data.id,
        name: data.name,
        description: data.description,
        coverTone: data.cover_tone,
        recipeIds: []
      };
    }

    if (error) {
      captureError(error, {
        action: "create_recipe_book",
        name: input.name
      });
      throw error;
    }
  }

  if (shouldUseSeedData) {
    return {
      id: `local-book-${Date.now()}`,
      name: input.name,
      description: input.description,
      coverTone: input.coverTone,
      recipeIds: []
    };
  }

  throw new Error("Cooksy could not create this book right now");
};

export const addRecipeToBookInBackend = async (recipeId: string, bookId: string): Promise<void> => {
  if (hasSupabaseConfig && supabase) {
    const { error } = await supabase.from("recipe_book_items").upsert(
      {
        book_id: bookId,
        recipe_id: recipeId
      },
      { onConflict: "book_id,recipe_id" }
    );

    if (error) {
      captureError(error, {
        action: "add_recipe_to_book",
        recipeId,
        bookId
      });
      throw error;
    }
  }

  trackEvent("recipe_added_to_book", {
    recipeId,
    bookId
  });
};

export const removeRecipeFromBookInBackend = async (recipeId: string, bookId: string): Promise<void> => {
  if (hasSupabaseConfig && supabase) {
    const { error } = await supabase.from("recipe_book_items").delete().eq("book_id", bookId).eq("recipe_id", recipeId);

    if (error) {
      captureError(error, {
        action: "remove_recipe_from_book",
        recipeId,
        bookId
      });
      throw error;
    }
  }

  trackEvent("recipe_removed_from_book", {
    recipeId,
    bookId
  });
};
