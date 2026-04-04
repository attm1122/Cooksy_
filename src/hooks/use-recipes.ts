import { useMutation, useQuery } from "@tanstack/react-query";

import {
  addRecipeToBookInBackend,
  createRecipeBookInBackend,
  fetchRecipeBooks,
  fetchRecentRecipes,
  importRecipeFromUrl,
  removeRecipeFromBookInBackend,
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
