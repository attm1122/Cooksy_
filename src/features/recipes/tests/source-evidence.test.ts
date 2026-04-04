import { aggregateSourceEvidence } from "@/features/recipes/lib/sourceEvidence";

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
});
