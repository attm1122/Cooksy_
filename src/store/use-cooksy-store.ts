import { create } from "zustand";

import { mockBooks, mockRecipes } from "@/mocks/recipes";
import type { ImportProgress, Recipe, RecipeBook } from "@/types/recipe";

type CooksyState = {
  recipes: Recipe[];
  books: RecipeBook[];
  selectedRecipeId?: string;
  lastCompletedRecipeId?: string;
  importProgress: ImportProgress;
  cookingRecipeId?: string;
  cookingStepIndex: number;
  setSelectedRecipe: (recipeId?: string) => void;
  setLastCompletedRecipeId: (recipeId?: string) => void;
  setImportProgress: (progress: Partial<ImportProgress>) => void;
  saveRecipe: (recipe: Recipe) => void;
  updateRecipe: (recipe: Recipe) => void;
  patchRecipe: (recipeId: string, patch: Partial<Recipe>) => void;
  removeRecipe: (recipeId: string) => void;
  mergeRecipes: (recipes: Recipe[]) => void;
  mergeBooks: (books: RecipeBook[]) => void;
  saveBook: (book: RecipeBook) => void;
  addRecipeToBook: (recipeId: string, bookId: string) => void;
  removeRecipeFromBook: (recipeId: string, bookId: string) => void;
  toggleIngredientChecked: (recipeId: string, ingredientId: string) => void;
  startCooking: (recipeId: string) => void;
  nextCookingStep: (stepCount: number) => void;
  previousCookingStep: () => void;
};

export const initialImportProgress: ImportProgress = {
  url: "",
  stage: "idle",
  progress: 0,
  detail: "Ready to import"
};

export const useCooksyStore = create<CooksyState>((set) => ({
  recipes: mockRecipes,
  books: mockBooks,
  selectedRecipeId: mockRecipes[0]?.id,
  lastCompletedRecipeId: undefined,
  importProgress: initialImportProgress,
  cookingRecipeId: undefined,
  cookingStepIndex: 0,
  setSelectedRecipe: (recipeId) => set({ selectedRecipeId: recipeId }),
  setLastCompletedRecipeId: (recipeId) => set({ lastCompletedRecipeId: recipeId }),
  setImportProgress: (progress) =>
    set((state) => ({
      importProgress: {
        ...state.importProgress,
        ...progress
      }
    })),
  saveRecipe: (recipe) =>
    set((state) => {
      const existing = state.recipes.find((item) => item.id === recipe.id);

      if (existing) {
        return {
          recipes: state.recipes.map((item) => (item.id === recipe.id ? { ...recipe, isSaved: true } : item))
        };
      }

      return {
        recipes: [{ ...recipe, isSaved: true }, ...state.recipes]
      };
    }),
  updateRecipe: (recipe) =>
    set((state) => ({
      recipes: state.recipes.map((item) => (item.id === recipe.id ? recipe : item))
    })),
  patchRecipe: (recipeId, patch) =>
    set((state) => ({
      recipes: state.recipes.map((item) => (item.id === recipeId ? { ...item, ...patch } : item))
    })),
  removeRecipe: (recipeId) =>
    set((state) => ({
      recipes: state.recipes.filter((item) => item.id !== recipeId && item.importJobId !== recipeId),
      books: state.books.map((book) => ({
        ...book,
        recipeIds: book.recipeIds.filter((id) => id !== recipeId)
      })),
      selectedRecipeId: state.selectedRecipeId === recipeId ? undefined : state.selectedRecipeId
    })),
  mergeRecipes: (recipes) =>
    set((state) => {
      const next = [...state.recipes];

      recipes.forEach((incoming) => {
        const existingIndex = next.findIndex(
          (item) =>
            item.id === incoming.id ||
            item.importJobId === incoming.importJobId ||
            item.source.url === incoming.source.url
        );

        if (existingIndex >= 0) {
          next[existingIndex] = {
            ...next[existingIndex],
            ...incoming
          };
          return;
        }

        next.unshift(incoming);
      });

      return { recipes: next };
    }),
  mergeBooks: (books) =>
    set((state) => {
      const next = [...state.books];

      books.forEach((incoming) => {
        const existingIndex = next.findIndex((item) => item.id === incoming.id);

        if (existingIndex >= 0) {
          next[existingIndex] = incoming;
          return;
        }

        next.unshift(incoming);
      });

      return { books: next };
    }),
  saveBook: (book) =>
    set((state) => {
      const existing = state.books.find((item) => item.id === book.id);

      if (existing) {
        return {
          books: state.books.map((item) => (item.id === book.id ? book : item))
        };
      }

      return { books: [book, ...state.books] };
    }),
  addRecipeToBook: (recipeId, bookId) =>
    set((state) => ({
      books: state.books.map((book) =>
        book.id === bookId && !book.recipeIds.includes(recipeId)
          ? { ...book, recipeIds: [...book.recipeIds, recipeId] }
          : book
      )
    })),
  removeRecipeFromBook: (recipeId, bookId) =>
    set((state) => ({
      books: state.books.map((book) =>
        book.id === bookId ? { ...book, recipeIds: book.recipeIds.filter((id) => id !== recipeId) } : book
      )
    })),
  toggleIngredientChecked: (recipeId, ingredientId) =>
    set((state) => ({
      recipes: state.recipes.map((recipe) =>
        recipe.id === recipeId
          ? {
              ...recipe,
              ingredients: recipe.ingredients.map((ingredient) =>
                ingredient.id === ingredientId ? { ...ingredient, checked: !ingredient.checked } : ingredient
              )
            }
          : recipe
      )
    })),
  startCooking: (recipeId) => set({ cookingRecipeId: recipeId, cookingStepIndex: 0 }),
  nextCookingStep: (stepCount) =>
    set((state) => ({
      cookingStepIndex: Math.min(state.cookingStepIndex + 1, stepCount - 1)
    })),
  previousCookingStep: () =>
    set((state) => ({
      cookingStepIndex: Math.max(state.cookingStepIndex - 1, 0)
    }))
}));
