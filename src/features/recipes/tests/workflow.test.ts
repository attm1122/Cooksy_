import { recipeRepository } from "@/features/recipes/services/recipeRepository";
import {
  createProcessingRecipe,
  failRecipeProcessing,
  importRecipeFromUrl
} from "@/features/recipes/services/recipeWorkflowService";

describe("recipe workflow service", () => {
  beforeEach(() => {
    recipeRepository.reset();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  const mockYouTubeFetch = () =>
    jest
      .spyOn(globalThis, "fetch")
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          title: "Creamy Garlic Chicken Orzo",
          author_name: "Cooksy Channel",
          thumbnail_url: "https://img.youtube.com/vi/cooksy-garlic-chicken/hqdefault.jpg"
        })
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        text: async () =>
          '<html><head><meta name="title" content="Creamy Garlic Chicken Orzo"></head><body>"shortDescription":"Sear chicken, add garlic, simmer with cream.","captions":{"playerCaptionsTracklistRenderer":{"captionTracks":[{"baseUrl":"https://captions.example/en","languageCode":"en"}]}}</body></html>'
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        text: async () =>
          '<?xml version="1.0"?><transcript><text start="0" dur="2">Season the chicken</text><text start="2" dur="2">Add garlic and cream</text></transcript>'
      } as Response);

  it("creates a processing recipe immediately", async () => {
    const recipe = await createProcessingRecipe("https://www.youtube.com/watch?v=cooksy123", "youtube");

    expect(recipe.status).toBe("processing");
    expect(recipe.thumbnailSource).toBe("youtube");
  });

  it("completes recipe processing after reconstruction", async () => {
    mockYouTubeFetch();
    const result = await importRecipeFromUrl("https://www.youtube.com/watch?v=cooksy-garlic-chicken");

    expect(result.status).toBe("completed");
    expect(result.ingredients.length).toBeGreaterThan(1);
    expect(result.steps.length).toBeGreaterThan(1);
  });

  it("handles failed recipes gracefully", async () => {
    const processingRecipe = await createProcessingRecipe("https://www.instagram.com/reel/CooksyTuscanPasta/", "instagram");
    await recipeRepository.create(processingRecipe);

    const failed = await failRecipeProcessing(processingRecipe.id, new Error("Import failed"));

    expect(failed.status).toBe("failed");
    expect(failed.validationWarnings[0]).toBe("Import failed");
  });

  it("updates a processing recipe in place on completion", async () => {
    mockYouTubeFetch();
    const processingRecipe = await createProcessingRecipe("https://www.youtube.com/watch?v=cooksy-garlic-chicken", "youtube");
    await recipeRepository.create(processingRecipe);
    const finalRecipe = await importRecipeFromUrl("https://www.youtube.com/watch?v=cooksy-garlic-chicken", {
      recipeId: processingRecipe.id
    });

    const storedRecipe = await recipeRepository.getById(processingRecipe.id);

    expect(finalRecipe.id).toBe(processingRecipe.id);
    expect(storedRecipe?.status).toBe("completed");
  });
});
