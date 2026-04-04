import { extractRecipeContextFromUrl, extractYouTubeContext } from "@/features/recipes/services/extractionService";

describe("extraction service", () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("hydrates YouTube context from live metadata when available", async () => {
    const fetchSpy = jest.spyOn(globalThis, "fetch").mockResolvedValue({
      ok: true,
      json: async () => ({
        title: "Live Garlic Chicken",
        author_name: "Cooksy Channel",
        thumbnail_url: "https://img.youtube.com/vi/abcdefghijk/hqdefault.jpg"
      })
    } as Response);

    const context = await extractYouTubeContext("https://www.youtube.com/watch?v=abcdefghijk");

    expect(context.title).toBe("Live Garlic Chicken");
    expect(context.creator).toBe("Cooksy Channel");
    expect(context.thumbnailUrl).toBe("https://img.youtube.com/vi/abcdefghijk/hqdefault.jpg");
    expect(fetchSpy).toHaveBeenCalled();
  });

  it("falls back to mocked extraction when live YouTube metadata fails", async () => {
    jest.spyOn(globalThis, "fetch").mockRejectedValue(new Error("network down"));

    const context = await extractRecipeContextFromUrl("https://www.youtube.com/watch?v=cooksy-garlic-chicken");

    expect(context.title).toContain("Creamy Garlic Chicken");
    expect(context.metadata?.extractionSource).toBe("mock-fallback");
  });
});
