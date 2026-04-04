import { z } from "zod";

export const sourcePlatformSchema = z.enum(["youtube", "tiktok", "instagram"]);
export const thumbnailSourceSchema = z.enum(["youtube", "tiktok", "instagram", "generated"]);

export const ingredientSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(2),
  quantity: z.string().nullable().optional(),
  unit: z.string().nullable().optional(),
  note: z.string().nullable().optional(),
  optional: z.boolean().optional(),
  inferred: z.boolean().optional()
});

export const evidenceSignalSchema = z.object({
  id: z.string().min(1),
  type: z.enum(["transcript", "caption", "ocr", "comment", "metadata"]),
  content: z.string().min(1),
  weight: z.number().min(0).max(1),
  source: z.string().min(1),
  timestamp: z.number().nonnegative().optional()
});

export const transcriptSegmentSchema = z.object({
  id: z.string().min(1),
  text: z.string().min(1),
  startSeconds: z.number().nonnegative().optional(),
  durationSeconds: z.number().nonnegative().optional(),
  sourceSignalId: z.string().optional()
});

export const ocrBlockSchema = z.object({
  id: z.string().min(1),
  text: z.string().min(1),
  context: z.string().nullable().optional(),
  timestampSeconds: z.number().nonnegative().optional(),
  boundingBox: z
    .object({
      x: z.number(),
      y: z.number(),
      width: z.number().nonnegative(),
      height: z.number().nonnegative()
    })
    .nullable()
    .optional(),
  sourceSignalId: z.string().optional()
});

export const recipeStepSchema = z.object({
  id: z.string().min(1),
  order: z.number().int().min(1),
  instruction: z.string().min(8),
  durationMinutes: z.number().int().nonnegative().nullable().optional(),
  temperature: z.string().nullable().optional(),
  inferred: z.boolean().optional()
});

export const rawRecipeContextSchema = z.object({
  sourceUrl: z.string().url(),
  platform: sourcePlatformSchema,
  title: z.string().nullable().optional(),
  creator: z.string().nullable().optional(),
  caption: z.string().nullable().optional(),
  transcript: z.string().nullable().optional(),
  ocrText: z.array(z.string()).nullable().optional(),
  comments: z.array(z.string()).nullable().optional(),
  metadata: z.record(z.string(), z.unknown()).nullable().optional(),
  thumbnailUrl: z.string().url().nullable().optional(),
  signals: z.array(evidenceSignalSchema).optional(),
  transcriptSegments: z.array(transcriptSegmentSchema).optional(),
  ocrBlocks: z.array(ocrBlockSchema).optional(),
  thumbnailCandidates: z.array(z.string().url()).optional(),
  creators: z.array(z.string()).optional(),
  titles: z.array(z.string()).optional()
});

export const confidenceReportSchema = z.object({
  score: z.number().min(0).max(1),
  warnings: z.array(z.string()),
  missingFields: z.array(z.string()),
  lowConfidenceAreas: z.array(z.string())
});

export const recipeSchema = z.object({
  id: z.string().min(1),
  sourceUrl: z.string().url(),
  sourcePlatform: sourcePlatformSchema,
  sourceCreator: z.string().nullable().optional(),
  sourceTitle: z.string().nullable().optional(),
  status: z.enum(["processing", "completed", "failed"]),
  title: z.string().min(3),
  description: z.string().nullable().optional(),
  servings: z.number().int().positive().nullable().optional(),
  prepTimeMinutes: z.number().int().nonnegative().nullable().optional(),
  cookTimeMinutes: z.number().int().nonnegative().nullable().optional(),
  totalTimeMinutes: z.number().int().nonnegative().nullable().optional(),
  ingredients: z.array(ingredientSchema).min(1),
  steps: z.array(recipeStepSchema).min(1),
  thumbnailUrl: z.string().url().nullable().optional(),
  thumbnailSource: thumbnailSourceSchema,
  thumbnailFallbackStyle: z.string().nullable().optional(),
  confidenceScore: z.number().min(0).max(100),
  confidenceReport: confidenceReportSchema,
  inferredFields: z.array(z.string()),
  missingFields: z.array(z.string()),
  validationWarnings: z.array(z.string()),
  rawExtraction: rawRecipeContextSchema.optional(),
  createdAt: z.string().min(1),
  updatedAt: z.string().min(1),
  isSynced: z.boolean()
});

export const processingRecipeSchema = recipeSchema.extend({
  status: z.literal("processing")
});
