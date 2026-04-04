import {
  buildPersistedRecipe,
  extractRecipeContextForImport,
  inferPlatformFromUrl,
  reconstructRecipe,
  type RawRecipeContext
} from "../supabase/functions/_shared/recipe-pipeline";

describe("server recipe pipeline", () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.resetAllMocks();
  });

  it("detects supported platforms from source urls", () => {
    expect(inferPlatformFromUrl("https://www.youtube.com/watch?v=abc123def45")).toBe("youtube");
    expect(inferPlatformFromUrl("https://www.tiktok.com/@cooksy/video/736382929292")).toBe("tiktok");
    expect(inferPlatformFromUrl("https://www.instagram.com/reel/C9cooksy123/")).toBe("instagram");
    expect(inferPlatformFromUrl("https://example.com/recipe")).toBeNull();
  });

  it("hydrates youtube extraction context from oembed when available", async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          title: "Creamy Garlic Chicken Orzo",
          author_name: "Weeknight Cook",
          author_url: "https://youtube.com/@weeknightcook",
          thumbnail_url: "https://i.ytimg.com/vi/abc123def45/hqdefault.jpg"
        })
      })
      .mockResolvedValueOnce({
        ok: true,
        text: async () =>
          '<html><head><meta name="title" content="Creamy Garlic Chicken Orzo"></head><body>"shortDescription":"One-pan creamy garlic chicken orzo.","captions":{"playerCaptionsTracklistRenderer":{"captionTracks":[{"baseUrl":"https://captions.example/en","languageCode":"en"}]}}</body></html>'
      })
      .mockResolvedValueOnce({
        ok: true,
        text: async () =>
          '<?xml version="1.0"?><transcript><text start="0" dur="2">Sear the chicken</text><text start="2" dur="2">Simmer the orzo</text></transcript>'
      }) as unknown as typeof fetch;

    const context = await extractRecipeContextForImport({
      sourceUrl: "https://www.youtube.com/watch?v=abc123def45",
      sourcePlatform: "youtube",
      sourcePayload: null
    });

    expect(context.title).toBe("Creamy Garlic Chicken Orzo");
    expect(context.creator).toBe("Weeknight Cook");
    expect(context.thumbnailUrl).toContain("i.ytimg.com");
    expect(context.caption).toContain("One-pan creamy");
    expect(context.transcript).toContain("Sear the chicken");
    expect(context.metadata?.extractionSource).toBe("youtube-oembed+watch");
  });

  it("reconstructs a trustworthy persisted recipe from raw context", async () => {
    const context: RawRecipeContext = {
      sourceUrl: "https://www.youtube.com/watch?v=abc123def45",
      platform: "youtube",
      title: "Creamy Garlic Chicken Orzo",
      creator: "Weeknight Cook",
      caption: "One-pan creamy garlic chicken orzo with parmesan and spinach.",
      transcript:
        "Season the chicken, sear until golden, then add garlic, butter, and dry orzo. Pour in chicken stock and cream, simmer until tender, then finish with spinach and parmesan.",
      metadata: {
        ingredientHints: [
          { name: "Chicken thighs", quantity: "6", note: "boneless skinless" },
          { name: "Garlic", inferred: true },
          { name: "Orzo", quantity: "1", unit: "cup" }
        ],
        stepHints: [
          { instruction: "Season and sear the chicken until golden.", durationMinutes: 8 },
          { instruction: "Add garlic and orzo, then simmer with stock and cream.", durationMinutes: 14 },
          { instruction: "Finish with spinach and parmesan and serve warm.", durationMinutes: 4 }
        ]
      },
      thumbnailUrl: "https://i.ytimg.com/vi/abc123def45/hqdefault.jpg"
    };

    const reconstruction = await reconstructRecipe(context);
    const recipe = buildPersistedRecipe({
      jobId: "job-123",
      sourceUrl: context.sourceUrl,
      sourcePlatform: context.platform,
      reconstruction
    });

    expect(reconstruction.ingredients).toHaveLength(3);
    expect(reconstruction.steps).toHaveLength(3);
    expect(reconstruction.inferredFields).toContain("Garlic inferred from partial source cues");
    expect(reconstruction.inferredFields).toContain("Garlic quantity inferred");
    expect(reconstruction.confidenceScore).toBeGreaterThan(60);
    expect(recipe.status).toBe("ready");
    expect(recipe.source.platform).toBe("youtube");
    expect(recipe.confidence).toBe("medium");
    expect(recipe.ingredients[1]?.quantity).toContain("4 cloves");
  });

  it("hydrates instagram source context from public page signals", async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      text: async () =>
        '<html><head><meta property="og:title" content="One Pan Tuscan Pasta"><meta property="og:description" content="Creamy tuscan pasta with sun-dried tomatoes."><meta property="og:image" content="https://cdn.example.com/pasta.jpg"><script type="application/ld+json">{"author":{"name":"Luca at Home"}}</script></head><body></body></html>'
    }) as unknown as typeof fetch;

    const context = await extractRecipeContextForImport({
      sourceUrl: "https://www.instagram.com/reel/CooksyTuscanPasta/",
      sourcePlatform: "instagram",
      sourcePayload: null
    });

    expect(context.title).toBe("One Pan Tuscan Pasta");
    expect(context.creator).toBe("Luca at Home");
    expect(context.caption).toContain("Creamy tuscan pasta");
    expect(context.thumbnailUrl).toBe("https://cdn.example.com/pasta.jpg");
    expect((context.metadata as { extractionSource?: string } | null)?.extractionSource).toBe("social-page");
  });
});
