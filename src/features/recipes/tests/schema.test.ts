import { recipeSchema } from "@/features/recipes/schemas/recipeSchemas";
import { createEmptyRecipe } from "@/features/recipes/domain/recipeDomain";

describe("feature recipe schema", () => {
  it("accepts a valid recipe", () => {
    const recipe = createEmptyRecipe({
      id: "recipe-1",
      sourceUrl: "https://www.youtube.com/watch?v=cooksy123",
      sourcePlatform: "youtube",
      thumbnailUrl: "https://img.youtube.com/vi/cooksy123/hqdefault.jpg",
      thumbnailSource: "youtube"
    });

    const completedRecipe = {
      ...recipe,
      status: "completed" as const,
      title: "Creamy Garlic Chicken",
      ingredients: [{ id: "ingredient-1", name: "Chicken", quantity: "2", unit: "pieces" }],
      steps: [{ id: "step-1", order: 1, instruction: "Cook the chicken until golden." }],
      confidenceScore: 82,
      missingFields: [],
      validationWarnings: []
    };

    expect(() => recipeSchema.parse(completedRecipe)).not.toThrow();
  });

  it("fails without ingredients", () => {
    const recipe = {
      ...createEmptyRecipe({
        id: "recipe-2",
        sourceUrl: "https://www.youtube.com/watch?v=cooksy123",
        sourcePlatform: "youtube",
        thumbnailSource: "youtube"
      }),
      status: "completed" as const,
      ingredients: [],
      steps: [{ id: "step-1", order: 1, instruction: "Cook the chicken until golden." }]
    };

    expect(() => recipeSchema.parse(recipe)).toThrow();
  });

  it("fails without steps", () => {
    const recipe = {
      ...createEmptyRecipe({
        id: "recipe-3",
        sourceUrl: "https://www.youtube.com/watch?v=cooksy123",
        sourcePlatform: "youtube",
        thumbnailSource: "youtube"
      }),
      status: "completed" as const,
      ingredients: [{ id: "ingredient-1", name: "Chicken", quantity: "2", unit: "pieces" }],
      steps: []
    };

    expect(() => recipeSchema.parse(recipe)).toThrow();
  });
});

