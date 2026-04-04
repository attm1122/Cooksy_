export type SourcePlatform = "youtube" | "tiktok" | "instagram";
export type ThumbnailSource = SourcePlatform | "generated";

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

export type Recipe = {
  id: string;
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
  confidenceNote: string;
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
