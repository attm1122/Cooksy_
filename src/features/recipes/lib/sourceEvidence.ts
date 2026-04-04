import type { RawRecipeContext, SourceEvidence } from "@/features/recipes/types";

const FOOD_CUES = [
  "chicken",
  "garlic",
  "cream",
  "parmesan",
  "spinach",
  "salmon",
  "honey",
  "rice",
  "pasta",
  "orzo",
  "stock",
  "butter",
  "tomato"
] as const;

const QUANTITY_PATTERN =
  /\b(\d+\s?\/\s?\d+|\d+\.\d+|\d+)\s*(cup|cups|tbsp|tablespoon|tablespoons|tsp|teaspoon|teaspoons|oz|ounce|ounces|lb|lbs|pound|pounds|clove|cloves|fillet|fillets|piece|pieces|handful|handfuls)\b/gi;

const normalizeText = (value: string | null | undefined) => value?.replace(/\s+/g, " ").trim() ?? "";

export const aggregateSourceEvidence = (context: RawRecipeContext): SourceEvidence => {
  const transcriptText = normalizeText(context.transcript);
  const captionText = normalizeText(context.caption);
  const ocrText = normalizeText(context.ocrText?.join(" "));
  const commentsText = normalizeText(context.comments?.join(" "));
  const combinedText = [captionText, transcriptText, ocrText, commentsText].filter(Boolean).join(" ").toLowerCase();

  const cueMentions = FOOD_CUES.filter((cue) => combinedText.includes(cue));
  const explicitQuantityMentions = Array.from(combinedText.matchAll(QUANTITY_PATTERN)).length;
  const signalOrigins = Array.isArray((context.metadata as { signalOrigins?: unknown } | null)?.signalOrigins)
    ? ((context.metadata as { signalOrigins: unknown[] }).signalOrigins.filter((item): item is string => typeof item === "string"))
    : [];

  return {
    combinedText,
    transcriptText,
    captionText,
    ocrText,
    commentsText,
    explicitQuantityMentions,
    cueMentions,
    hasStrongTranscript: transcriptText.length > 120,
    hasAnyTextSignals: Boolean(combinedText),
    signalOriginCount: signalOrigins.length
  };
};
