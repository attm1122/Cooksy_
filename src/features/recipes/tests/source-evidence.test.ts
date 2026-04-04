import { aggregateEvidence, aggregateSourceEvidence, hydrateEvidenceContext } from "@/features/recipes/lib/sourceEvidence";

describe("source evidence aggregation", () => {
  it("combines transcript, caption, ocr, and comments into one evidence bundle", () => {
    const evidence = aggregateSourceEvidence({
      sourceUrl: "https://www.youtube.com/watch?v=abc123def45",
      platform: "youtube",
      title: "Creamy Garlic Chicken",
      creator: "Cooksy Creator",
      caption: "One pan creamy chicken.",
      transcript: "Use 2 cups of stock and 4 cloves of garlic.",
      ocrText: ["1 cup orzo", "spinach"],
      comments: ["I used parmesan and it was great."],
      metadata: {
        signalOrigins: ["oembed", "watch-page"]
      },
      thumbnailUrl: null
    });

    expect(evidence.hasAnyTextSignals).toBe(true);
    expect(evidence.explicitQuantityMentions).toBeGreaterThanOrEqual(2);
    expect(evidence.cueMentions).toEqual(expect.arrayContaining(["chicken", "garlic", "spinach"]));
    expect(evidence.signalOriginCount).toBe(2);
  });

  it("hydrates raw recipe context into ranked titles and evidence signals", () => {
    const context = hydrateEvidenceContext({
      sourceUrl: "https://www.youtube.com/watch?v=abc123def45",
      platform: "youtube",
      title: "Creamy Garlic Chicken",
      creator: "Cooksy Creator",
      caption: "One pan creamy chicken.",
      transcript: "Use 2 cups of stock and 4 cloves of garlic.",
      ocrText: ["1 cup orzo", "spinach"],
      comments: ["I used parmesan and it was great."],
      metadata: {
        signalOrigins: ["oembed", "watch-page"]
      },
      thumbnailUrl: "https://img.youtube.com/vi/abc123def45/hqdefault.jpg"
    });

    expect(context.signals?.length).toBeGreaterThan(3);
    expect(context.transcriptSegments?.length).toBeGreaterThan(0);
    expect(context.titles?.[0]).toBe("Creamy Garlic Chicken");
    expect(context.thumbnailCandidates?.[0]).toContain("img.youtube.com");
  });

  it("aggregates candidate ingredients and steps with supporting signals", () => {
    const aggregated = aggregateEvidence({
      sourceUrl: "https://www.tiktok.com/@cooksy/video/strong456",
      platform: "tiktok",
      title: "Salmon Rice Bowl",
      creator: "Cooksy",
      caption: "Crispy salmon rice bowl with hot honey glaze.",
      transcript: "Roast two salmon fillets, mix three tablespoons of honey, then serve over rice.",
      ocrText: ["2 salmon fillets", "3 tbsp honey"],
      comments: ["I added garlic butter to the glaze."],
      metadata: {
        signalOrigins: ["open-graph"],
        ingredientHints: [],
        stepHints: []
      },
      thumbnailUrl: "https://cdn.example.com/salmon.jpg"
    });

    expect(aggregated.ingredients.some((ingredient) => ingredient.name === "Salmon Fillets" || ingredient.name === "Salmon")).toBe(true);
    expect(aggregated.ingredients.every((ingredient) => ingredient.supportingSignals.length > 0)).toBe(true);
    expect(aggregated.steps.some((step) => step.actionVerb)).toBe(true);
  });
});
