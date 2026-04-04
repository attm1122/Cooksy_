import { z } from "zod";
import { isSupportedSourceUrl } from "@/utils/source-url";

export const sourcePlatformSchema = z.enum(["youtube", "tiktok", "instagram"]);

export const ingredientSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(2, "Ingredient name is required"),
  quantity: z.string().min(1, "Quantity is required"),
  optional: z.boolean().optional(),
  checked: z.boolean().optional()
});

export const recipeStepSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(2, "Step title is required"),
  instruction: z.string().min(8, "Instruction should be descriptive"),
  durationMinutes: z.number().int().nonnegative().optional()
});

export const recipeSchema = z.object({
  id: z.string().min(1),
  status: z.enum(["processing", "ready", "failed"]),
  importJobId: z.string().optional(),
  processingMessage: z.string().optional(),
  title: z.string().min(3),
  description: z.string().min(10),
  heroNote: z.string().min(5),
  imageLabel: z.string().min(2),
  thumbnailUrl: z.string().url().nullable(),
  thumbnailSource: z.enum(["youtube", "tiktok", "instagram", "generated"]),
  thumbnailFallbackStyle: z.string().optional(),
  servings: z.number().int().positive(),
  prepTimeMinutes: z.number().int().nonnegative(),
  cookTimeMinutes: z.number().int().nonnegative(),
  totalTimeMinutes: z.number().int().nonnegative(),
  confidence: z.enum(["high", "medium", "low"]),
  confidenceScore: z.number().min(0).max(100),
  confidenceNote: z.string().min(8),
  confidenceReport: z
    .object({
      score: z.number().min(0).max(1),
      warnings: z.array(z.string()),
      missingFields: z.array(z.string()),
      lowConfidenceAreas: z.array(z.string())
    })
    .optional(),
  inferredFields: z.array(z.string()).default([]),
  missingFields: z.array(z.string()).default([]),
  warnings: z.array(z.string()).default([]),
  editableFields: z.array(z.string()).default([]),
  isSaved: z.boolean(),
  source: z.object({
    creator: z.string().min(2),
    url: z.string().url(),
    platform: sourcePlatformSchema
  }),
  ingredients: z.array(ingredientSchema).min(1),
  steps: z.array(recipeStepSchema).min(1),
  tags: z.array(z.string()).default([])
});

export const recipeBookSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(2),
  description: z.string().min(4),
  coverTone: z.enum(["yellow", "cream", "ink"]),
  recipeIds: z.array(z.string())
});

export const importRecipeSchema = z.object({
  sourceUrl: z
    .string()
    .url("Please paste a valid share link")
    .refine(isSupportedSourceUrl, "Cooksy currently supports YouTube, TikTok, and Instagram recipe links")
});

export type RecipeFormValues = z.infer<typeof recipeSchema>;
export type RecipeBookFormValues = z.infer<typeof recipeBookSchema>;
export type ImportRecipeFormValues = z.infer<typeof importRecipeSchema>;
