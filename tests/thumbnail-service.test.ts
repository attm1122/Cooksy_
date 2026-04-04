import { getThumbnailFromUrl } from "@/features/recipes/services/thumbnailService";
import { mockRecipes } from "@/mocks/recipes";

describe("thumbnailService", () => {
  it("derives a predictable youtube thumbnail", async () => {
    const result = await getThumbnailFromUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
    expect(result.thumbnailSource).toBe("youtube");
    expect(result.thumbnailUrl).toContain("img.youtube.com/vi/dQw4w9WgXcQ");
  });

  it("returns an intentional fallback style for recipes", async () => {
    const result = await getThumbnailFromUrl(mockRecipes[1].source.url);
    expect(result.thumbnailFallbackStyle).toBeTruthy();
    expect(result.thumbnailSource).toBe("tiktok");
  });
});
