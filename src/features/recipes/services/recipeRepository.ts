import type { Recipe } from "@/features/recipes/types";

export type RecipeRepository = {
  create: (recipe: Recipe) => Promise<Recipe>;
  update: (recipeId: string, patch: Partial<Recipe>) => Promise<Recipe>;
  getById: (recipeId: string) => Promise<Recipe | undefined>;
  list: () => Promise<Recipe[]>;
  reset: () => void;
};

const cloneRecipe = <T>(value: T): T => JSON.parse(JSON.stringify(value));

class InMemoryRecipeRepository implements RecipeRepository {
  private recipes = new Map<string, Recipe>();

  async create(recipe: Recipe) {
    this.recipes.set(recipe.id, cloneRecipe(recipe));
    return cloneRecipe(recipe);
  }

  async update(recipeId: string, patch: Partial<Recipe>) {
    const existing = this.recipes.get(recipeId);

    if (!existing) {
      throw new Error(`Recipe ${recipeId} not found`);
    }

    const updated = {
      ...existing,
      ...patch,
      updatedAt: new Date().toISOString()
    };

    this.recipes.set(recipeId, cloneRecipe(updated));
    return cloneRecipe(updated);
  }

  async getById(recipeId: string) {
    const recipe = this.recipes.get(recipeId);
    return recipe ? cloneRecipe(recipe) : undefined;
  }

  async list() {
    return Array.from(this.recipes.values()).map((recipe) => cloneRecipe(recipe));
  }

  reset() {
    this.recipes.clear();
  }
}

export const recipeRepository = new InMemoryRecipeRepository();

