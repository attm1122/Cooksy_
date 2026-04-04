export type SourcePlatform = "youtube" | "tiktok" | "instagram";
export type ThumbnailSource = SourcePlatform | "generated";
export type RecipeStatus = "processing" | "ready" | "failed";

export type RecipeConfidenceLevel = "high" | "medium" | "low";

export type RecipeIngredient = {
  id: string;
  name: string;
  quantity: string;
  optional?: boolean;
  checked?: boolean;
};

export type RecipeStep = {
  id: string;
  title: string;
  instruction: string;
  durationMinutes?: number;
};

export type RecipeSource = {
  creator: string;
  url: string;
  platform: SourcePlatform;
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
  signals?: {
    id: string;
    type: "transcript" | "caption" | "ocr" | "comment" | "metadata";
    content: string;
    weight: number;
    source: string;
    timestamp?: number;
  }[];
  transcriptSegments?: {
    id: string;
    text: string;
    startSeconds?: number;
    durationSeconds?: number;
    sourceSignalId?: string;
  }[];
  ocrBlocks?: {
    id: string;
    text: string;
    context?: string | null;
    timestampSeconds?: number;
    sourceSignalId?: string;
  }[];
  thumbnailCandidates?: string[];
  creators?: string[];
  titles?: string[];
};

export type ConfidenceReport = {
  score: number;
  warnings: string[];
  missingFields: string[];
  lowConfidenceAreas: string[];
};

export type Recipe = {
  id: string;
  status: RecipeStatus;
  importJobId?: string;
  processingMessage?: string;
  title: string;
  description: string;
  heroNote: string;
  imageLabel: string;
  thumbnailUrl: string | null;
  thumbnailSource: ThumbnailSource;
  thumbnailFallbackStyle?: string;
  servings: number;
  prepTimeMinutes: number;
  cookTimeMinutes: number;
  totalTimeMinutes: number;
  confidence: RecipeConfidenceLevel;
  confidenceScore: number;
  confidenceNote: string;
  confidenceReport?: ConfidenceReport;
  inferredFields: string[];
  missingFields: string[];
  warnings: string[];
  editableFields: string[];
  rawExtraction?: RawRecipeContext;
  isSaved: boolean;
  source: RecipeSource;
  ingredients: RecipeIngredient[];
  steps: RecipeStep[];
  tags: string[];
};

export type RecipeBook = {
  id: string;
  name: string;
  description: string;
  coverTone: "yellow" | "cream" | "ink";
  recipeIds: string[];
};

export type ImportStage = "idle" | "queued" | "extracting" | "ingredients" | "steps" | "complete" | "error";

export type ImportProgress = {
  jobId?: string;
  url: string;
  stage: ImportStage;
  progress: number;
  detail?: string;
  errorMessage?: string;
};
