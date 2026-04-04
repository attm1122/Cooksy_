import { useMutation, useQuery } from "@tanstack/react-query";

import { fetchRecipeBooks, fetchRecentRecipes, importRecipeFromUrl } from "@/services/recipe-service";
import type { ImportProgress } from "@/types/recipe";

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
