import { extractRecipeContextFromUrl, extractYouTubeContext } from "@/features/recipes/services/extractionService";

describe("extraction service", () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("hydrates YouTube context from live metadata when available", async () => {
    const fetchSpy = jest
      .spyOn(globalThis, "fetch")
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          title: "Live Garlic Chicken",
          author_name: "Cooksy Channel",
          thumbnail_url: "https://img.youtube.com/vi/abcdefghijk/hqdefault.jpg"
        })
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        text: async () =>
          '<html><head><meta name="title" content="Live Garlic Chicken"></head><body>"shortDescription":"Sear chicken, add garlic, simmer with cream.","captions":{"playerCaptionsTracklistRenderer":{"captionTracks":[{"baseUrl":"https://captions.example/en","languageCode":"en"}]}}</body></html>'
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        text: async () =>
          '<?xml version="1.0"?><transcript><text start="0" dur="2">Season the chicken</text><text start="2" dur="2">Add garlic and cream</text></transcript>'
      } as Response);

    const context = await extractYouTubeContext("https://www.youtube.com/watch?v=abcdefghijk");

    expect(context.title).toBe("Live Garlic Chicken");
    expect(context.creator).toBe("Cooksy Channel");
    expect(context.thumbnailUrl).toBe("https://img.youtube.com/vi/abcdefghijk/hqdefault.jpg");
    expect(context.caption).toContain("Sear chicken");
    expect(context.transcript).toContain("Season the chicken");
    expect(context.metadata?.captionTrackCount).toBe(1);
    expect(context.metadata?.extractionSource).toBe("youtube-oembed+watch");
    expect(fetchSpy).toHaveBeenCalled();
  });

  it("falls back to mocked extraction when live YouTube metadata fails", async () => {
    jest.spyOn(globalThis, "fetch").mockRejectedValue(new Error("network down"));

    const context = await extractRecipeContextFromUrl("https://www.youtube.com/watch?v=cooksy-garlic-chicken");

    expect(context.title).toContain("Creamy Garlic Chicken");
    expect(context.metadata?.extractionSource).toBe("mock-fallback");
  });
});
