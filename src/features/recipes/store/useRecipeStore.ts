import { create } from "zustand";

import { recipeRepository } from "@/features/recipes/services/recipeRepository";
import { startRecipeImport } from "@/features/recipes/services/recipeWorkflowService";
import type { Recipe } from "@/features/recipes/types";

type RecipeStoreState = {
  recipes: Recipe[];
  importingRecipeIds: string[];
  selectedRecipeId?: string;
  importRecipe: (url: string) => Promise<Recipe>;
  saveRecipe: (recipe: Recipe) => void;
  updateRecipe: (recipeId: string, patch: Partial<Recipe>) => Promise<Recipe | undefined>;
  setSelectedRecipe: (recipeId?: string) => void;
  hydrateRecipes: () => Promise<void>;
  reset: () => void;
};

export const useRecipeStore = create<RecipeStoreState>((set, get) => ({
  recipes: [],
  importingRecipeIds: [],
  selectedRecipeId: undefined,
  async importRecipe(url) {
    const { processingRecipe, completion } = await startRecipeImport(url, {
      onStageChange: (stage, recipeId) => {
        if (stage === "completed" || stage === "failed") {
          set((state) => ({
            importingRecipeIds: state.importingRecipeIds.filter((id) => id !== recipeId)
          }));
          return;
        }

        set((state) =>
          state.importingRecipeIds.includes(recipeId)
            ? state
            : {
                importingRecipeIds: [...state.importingRecipeIds, recipeId]
              }
        );
      }
    });

    set((state) => ({
      recipes: [processingRecipe, ...state.recipes.filter((recipe) => recipe.id !== processingRecipe.id)],
      importingRecipeIds: state.importingRecipeIds.includes(processingRecipe.id)
        ? state.importingRecipeIds
        : [...state.importingRecipeIds, processingRecipe.id],
      selectedRecipeId: processingRecipe.id
    }));

    const completedRecipe = await completion;

    set((state) => ({
      recipes: state.recipes.map((recipe) => (recipe.id === completedRecipe.id ? completedRecipe : recipe)),
      importingRecipeIds: state.importingRecipeIds.filter((id) => id !== completedRecipe.id)
    }));

    return completedRecipe;
  },
  saveRecipe(recipe) {
    void recipeRepository.create(recipe);
    set((state) => ({
      recipes: [recipe, ...state.recipes.filter((item) => item.id !== recipe.id)]
    }));
  },
  async updateRecipe(recipeId, patch) {
    const existing = await recipeRepository.getById(recipeId);

    if (!existing) {
      return undefined;
    }

    const updated = await recipeRepository.update(recipeId, patch);
    set((state) => ({
      recipes: state.recipes.map((recipe) => (recipe.id === recipeId ? updated : recipe))
    }));
    return updated;
  },
  setSelectedRecipe(recipeId) {
    set({ selectedRecipeId: recipeId });
  },
  async hydrateRecipes() {
    const recipes = await recipeRepository.list();
    set({ recipes });
  },
  reset() {
    recipeRepository.reset();
    set({
      recipes: [],
      importingRecipeIds: [],
      selectedRecipeId: undefined
    });
  }
}));

