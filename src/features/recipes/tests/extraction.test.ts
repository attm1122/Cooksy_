import {
  extractInstagramContext,
  extractRecipeContextFromUrl,
  extractTikTokContext,
  extractYouTubeContext
} from "@/features/recipes/services/extractionService";

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

  it("hydrates TikTok context from public page signals when available", async () => {
    jest.spyOn(globalThis, "fetch").mockResolvedValue({
      ok: true,
      text: async () =>
        '<html><head><meta property="og:title" content="Crispy Hot Honey Salmon"><meta property="og:description" content="Sticky salmon rice bowls for weeknights."><meta property="og:image" content="https://cdn.example.com/salmon.jpg"><script type="application/ld+json">{"author":{"name":"Nina Cooks"}}</script></head><body>@ninacooks</body></html>'
    } as Response);

    const context = await extractTikTokContext("https://www.tiktok.com/@ninacooks/video/123456789");

    expect(context.title).toBe("Crispy Hot Honey Salmon");
    expect(context.creator).toBe("Nina Cooks");
    expect(context.caption).toContain("Sticky salmon");
    expect(context.thumbnailUrl).toBe("https://cdn.example.com/salmon.jpg");
    expect(context.metadata?.extractionSource).toBe("social-page");
  });

  it("hydrates Instagram context from public page signals when available", async () => {
    jest.spyOn(globalThis, "fetch").mockResolvedValue({
      ok: true,
      text: async () =>
        '<html><head><meta property="og:title" content="One Pan Tuscan Pasta"><meta property="og:description" content="Creamy tuscan pasta with spinach and parmesan."><meta property="og:image" content="https://cdn.example.com/pasta.jpg"><script type="application/ld+json">{"author":{"name":"Luca at Home"}}</script></head><body></body></html>'
    } as Response);

    const context = await extractInstagramContext("https://www.instagram.com/reel/CooksyTuscanPasta/");

    expect(context.title).toBe("One Pan Tuscan Pasta");
    expect(context.creator).toBe("Luca at Home");
    expect(context.caption).toContain("Creamy tuscan pasta");
    expect(context.thumbnailUrl).toBe("https://cdn.example.com/pasta.jpg");
    expect(context.metadata?.extractionSource).toBe("social-page");
  });
});
