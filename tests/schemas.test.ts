import { importRecipeSchema, recipeSchema } from "@/lib/schemas";
import { mockRecipes } from "@/mocks/recipes";

describe("recipeSchema", () => {
  it("accepts a valid mocked recipe", () => {
    expect(() => recipeSchema.parse(mockRecipes[0])).not.toThrow();
  });

  it("rejects an invalid import url", () => {
    expect(() => importRecipeSchema.parse({ sourceUrl: "not-a-url" })).toThrow();
  });
});
