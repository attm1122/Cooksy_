import { mockBooks, mockRecipes } from "@/mocks/recipes";
import type { ImportProgress, Recipe, RecipeBook } from "@/types/recipe";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const inferPlatformFromUrl = (url: string): Recipe["source"]["platform"] => {
  if (url.includes("tiktok")) {
    return "tiktok";
  }

  if (url.includes("instagram")) {
    return "instagram";
  }

  return "youtube";
};

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
): Promise<Recipe> => {
  const platform = inferPlatformFromUrl(url);

  onProgress?.({ url, stage: "extracting", progress: 0.25 });
  await sleep(500);

  onProgress?.({ url, stage: "ingredients", progress: 0.58 });
  await sleep(450);

  onProgress?.({ url, stage: "steps", progress: 0.88 });
  await sleep(450);

  const importedRecipe: Recipe = {
    ...mockRecipes[0],
    id: "imported-cooksy-demo",
    title: "Cooksy Imported Chicken Orzo",
    description: "A mocked import showing how Cooksy turns short-form cooking content into a structured recipe.",
    heroNote: "Generated from a shared video link with quantities and timings inferred for home cooking.",
    imageLabel: "Imported chicken orzo skillet",
    source: {
      creator: "Imported Creator",
      url,
      platform
    },
    confidence: "medium",
    confidenceNote: "Exact stock amount and final simmer timing were inferred from visual cues in the source clip."
  };

  onProgress?.({ url, stage: "complete", progress: 1 });
  await sleep(150);

  return importedRecipe;
};
