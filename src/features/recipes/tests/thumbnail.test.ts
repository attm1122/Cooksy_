import { getThumbnailFromContext, getThumbnailFromUrl, generateFallbackThumbnailStyle } from "@/features/recipes/services/thumbnailService";

describe("feature thumbnail service", () => {
  it("resolves YouTube thumbnails from the video id", async () => {
    const result = await getThumbnailFromUrl("https://www.youtube.com/watch?v=abcdefghijk");

    expect(result.thumbnailUrl).toBe("https://img.youtube.com/vi/abcdefghijk/hqdefault.jpg");
    expect(result.thumbnailSource).toBe("youtube");
  });

  it("falls back deterministically when thumbnail data is missing", () => {
    const thumbnail = getThumbnailFromContext({
      sourceUrl: "https://www.instagram.com/reel/CooksyPasta/",
      platform: "instagram",
      title: "Cooksy Pasta",
      creator: null
    });
    const fallbackStyle = generateFallbackThumbnailStyle("Cooksy Pasta", "instagram");

    expect(thumbnail).toContain("instagram-CooksyPasta");
    expect(fallbackStyle).toBeTruthy();
  });
});
