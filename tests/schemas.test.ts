import { importRecipeSchema, recipeSchema } from "@/lib/schemas";
import { mockRecipes } from "@/mocks/recipes";

describe("recipeSchema", () => {
  it("accepts a valid mocked recipe", () => {
    expect(() => recipeSchema.parse(mockRecipes[0])).not.toThrow();
  });

  it("rejects an invalid import url", () => {
    expect(() => importRecipeSchema.parse({ sourceUrl: "not-a-url" })).toThrow();
  });

  it("rejects unsupported source platforms", () => {
    expect(() => importRecipeSchema.parse({ sourceUrl: "https://example.com/watch?v=recipe" })).toThrow(
      "Cooksy currently supports YouTube, TikTok, and Instagram recipe links"
    );
  });

  it("accepts supported social share links", () => {
    expect(() => importRecipeSchema.parse({ sourceUrl: "https://www.youtube.com/watch?v=cooksy123" })).not.toThrow();
    expect(() => importRecipeSchema.parse({ sourceUrl: "https://www.tiktok.com/@cooksy/video/123456789" })).not.toThrow();
    expect(() => importRecipeSchema.parse({ sourceUrl: "https://www.instagram.com/reel/CooksyPasta/" })).not.toThrow();
  });
});
