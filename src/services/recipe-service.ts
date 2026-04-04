import { mockBooks, mockRecipes } from "@/mocks/recipes";
import { importRecipeFromUrl as runImportRecipe } from "@/services/import-service";
import type { ImportProgress, Recipe, RecipeBook } from "@/types/recipe";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export const fetchRecentRecipes = async (): Promise<Recipe[]> => {
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
