import { useMutation, useQuery } from "@tanstack/react-query";

import {
  addRecipeToBookInBackend,
  beginRecipeImport,
  createRecipeBookInBackend,
  fetchRecipeBooks,
  fetchRecentRecipes,
  importRecipeFromUrl,
  pollImportJobUntilComplete,
  removeRecipeFromBookInBackend,
  retryRecipeImport,
  updateRecipeInBackend
} from "@/services/recipe-service";
import type { ImportProgress, Recipe, RecipeBook } from "@/types/recipe";

export const useRecentRecipes = () =>
  useQuery({
    queryKey: ["recipes", "recent"],
    queryFn: fetchRecentRecipes
  });

export const useRecipeBooks = () =>
  useQuery({
    queryKey: ["books"],
    queryFn: fetchRecipeBooks
  });

export const useImportRecipe = (onProgress?: (progress: ImportProgress) => void) =>
  useMutation({
    mutationFn: (url: string) => importRecipeFromUrl(url, onProgress)
  });

export const useBeginRecipeImport = () =>
  useMutation({
    mutationFn: (url: string) => beginRecipeImport(url)
  });

export const useCompleteImportJob = (onProgress?: (progress: ImportProgress) => void) =>
  useMutation({
    mutationFn: (jobId: string) => pollImportJobUntilComplete(jobId, onProgress)
  });

export const useRetryRecipeImport = (onProgress?: (progress: ImportProgress) => void) =>
  useMutation({
    mutationFn: (recipe: Pick<Recipe, "id" | "source">) => retryRecipeImport(recipe, onProgress)
  });

export const useUpdateRecipe = () =>
  useMutation({
    mutationFn: (recipe: Recipe) => updateRecipeInBackend(recipe)
  });

export const useCreateRecipeBook = () =>
  useMutation({
    mutationFn: (input: Pick<RecipeBook, "name" | "description" | "coverTone">) => createRecipeBookInBackend(input)
  });

export const useAddRecipeToBook = () =>
  useMutation({
    mutationFn: ({ recipeId, bookId }: { recipeId: string; bookId: string }) => addRecipeToBookInBackend(recipeId, bookId)
  });

export const useRemoveRecipeFromBook = () =>
  useMutation({
    mutationFn: ({ recipeId, bookId }: { recipeId: string; bookId: string }) => removeRecipeFromBookInBackend(recipeId, bookId)
  });
