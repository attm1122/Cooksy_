import { reconstructRecipe } from "@/features/recipes/services/recipeReconstructionService";
import { getMockContextForUrl } from "@/features/recipes/mocks/sourceContexts";

describe("recipe reconstruction service", () => {
  it("reconstructs a structured recipe from mocked context", async () => {
    const context = getMockContextForUrl("https://www.youtube.com/watch?v=cooksy-garlic-chicken", "youtube");
    const result = await reconstructRecipe(context);

    expect(result.title).toContain("Creamy Garlic Chicken");
    expect(result.ingredients.length).toBeGreaterThan(2);
    expect(result.steps.length).toBeGreaterThan(2);
    expect(result.confidenceScore).toBeGreaterThan(70);
  });

  it("populates inferred fields when source data is incomplete", async () => {
    const context = getMockContextForUrl("https://www.instagram.com/reel/CooksyTuscanPasta/", "instagram");
    const result = await reconstructRecipe(context);

    expect(result.inferredFields.length).toBeGreaterThan(0);
    expect(result.missingFields).toContain("Parmesan quantity not provided");
  });

  it("drops confidence when source context is weak", async () => {
    const weakContext = {
      sourceUrl: "https://www.tiktok.com/@cooksy/video/weak123",
      platform: "tiktok" as const,
      title: "Quick Pasta",
      creator: null,
      caption: "Quick pasta.",
      transcript: null,
      ocrText: null,
      comments: null,
      metadata: {
        ingredientHints: [{ name: "Pasta", quantity: null, unit: null }],
        stepHints: [{ instruction: "Cook the pasta." }]
      },
      thumbnailUrl: null
    };
    const result = await reconstructRecipe(weakContext);

    expect(result.confidenceScore).toBeLessThan(65);
    expect(result.validationWarnings.length).toBeGreaterThan(0);
  });
});

