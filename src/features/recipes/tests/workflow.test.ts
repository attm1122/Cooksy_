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

  it("creates a processing recipe immediately", async () => {
    const recipe = await createProcessingRecipe("https://www.youtube.com/watch?v=cooksy123", "youtube");

    expect(recipe.status).toBe("processing");
    expect(recipe.thumbnailSource).toBe("youtube");
  });

  it("completes recipe processing after reconstruction", async () => {
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
