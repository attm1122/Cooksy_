export type SourcePlatform = "youtube" | "tiktok" | "instagram";
export type ThumbnailSource = SourcePlatform | "generated";
export type RecipeProcessingStatus = "processing" | "completed" | "failed";

export type Ingredient = {
  id: string;
  name: string;
  quantity?: string | null;
  unit?: string | null;
  note?: string | null;
  optional?: boolean;
  inferred?: boolean;
};

export type RecipeStep = {
  id: string;
  order: number;
  instruction: string;
  durationMinutes?: number | null;
  temperature?: string | null;
  inferred?: boolean;
};

export type RawRecipeContext = {
  sourceUrl: string;
  platform: SourcePlatform;
  title?: string | null;
  creator?: string | null;
  caption?: string | null;
  transcript?: string | null;
  ocrText?: string[] | null;
  comments?: string[] | null;
  metadata?: Record<string, unknown> | null;
  thumbnailUrl?: string | null;
};

export type Recipe = {
  id: string;
  sourceUrl: string;
  sourcePlatform: SourcePlatform;
  sourceCreator?: string | null;
  sourceTitle?: string | null;
  status: RecipeProcessingStatus;
  title: string;
  description?: string | null;
  servings?: number | null;
  prepTimeMinutes?: number | null;
  cookTimeMinutes?: number | null;
  totalTimeMinutes?: number | null;
  ingredients: Ingredient[];
  steps: RecipeStep[];
  thumbnailUrl?: string | null;
  thumbnailSource: ThumbnailSource;
  thumbnailFallbackStyle?: string | null;
  confidenceScore: number;
  inferredFields: string[];
  missingFields: string[];
  validationWarnings: string[];
  rawExtraction?: RawRecipeContext;
  createdAt: string;
  updatedAt: string;
  isSynced: boolean;
};

export type ReconstructionResult = {
  title: string;
  description?: string | null;
  servings?: number | null;
  prepTimeMinutes?: number | null;
  cookTimeMinutes?: number | null;
  totalTimeMinutes?: number | null;
  ingredients: Ingredient[];
  steps: RecipeStep[];
  thumbnailUrl?: string | null;
  thumbnailSource: ThumbnailSource;
  thumbnailFallbackStyle?: string | null;
  sourceCreator?: string | null;
  sourceTitle?: string | null;
  confidenceScore: number;
  inferredFields: string[];
  missingFields: string[];
  validationWarnings: string[];
  rawExtraction: RawRecipeContext;
};

export type ParsedYouTubeUrl = {
  platform: "youtube";
  normalizedUrl: string;
  videoId: string | null;
};

export type ParsedTikTokUrl = {
  platform: "tiktok";
  normalizedUrl: string;
  creatorHandle: string | null;
  videoId: string | null;
};

export type ParsedInstagramUrl = {
  platform: "instagram";
  normalizedUrl: string;
  mediaCode: string | null;
};

export type ParsedRecipeUrl = ParsedYouTubeUrl | ParsedTikTokUrl | ParsedInstagramUrl;

