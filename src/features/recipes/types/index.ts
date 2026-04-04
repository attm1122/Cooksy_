export type SourcePlatform = "youtube" | "tiktok" | "instagram";
export type ThumbnailSource = SourcePlatform | "generated";
export type RecipeProcessingStatus = "processing" | "completed" | "failed";
export type SourceSignalOrigin = "oembed" | "watch-page" | "open-graph" | "json-ld" | "mock-fallback";
export type EvidenceSignalType = "transcript" | "caption" | "ocr" | "comment" | "metadata";

export type EvidenceSignal = {
  id: string;
  type: EvidenceSignalType;
  content: string;
  weight: number;
  source: string;
  timestamp?: number;
};

export type RankedTextCandidate = {
  value: string;
  weight: number;
  source: string;
};

export type TranscriptSegment = {
  id: string;
  text: string;
  startSeconds?: number;
  durationSeconds?: number;
  sourceSignalId?: string;
};

export type OcrBlock = {
  id: string;
  text: string;
  context?: string | null;
  timestampSeconds?: number;
  boundingBox?: {
    x: number;
    y: number;
    width: number;
    height: number;
  } | null;
  sourceSignalId?: string;
};

export type IngredientSignal = {
  id: string;
  name: string;
  quantity?: string | null;
  unit?: string | null;
  note?: string | null;
  weight: number;
  source: string;
  sourceSignalIds: string[];
  timestamp?: number;
};

export type StepSignal = {
  id: string;
  instruction: string;
  action?: string | null;
  object?: string | null;
  weight: number;
  source: string;
  sourceSignalIds: string[];
  timestamp?: number;
};

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
  signals?: EvidenceSignal[];
  transcriptSegments?: TranscriptSegment[];
  ocrBlocks?: OcrBlock[];
  ingredientSignals?: IngredientSignal[];
  stepSignals?: StepSignal[];
  thumbnailCandidates?: string[];
  creators?: string[];
  titles?: string[];
  titleCandidates?: RankedTextCandidate[];
};

export type SourceSignals = {
  title?: string | null;
  description?: string | null;
  creator?: string | null;
  thumbnailUrl?: string | null;
  transcript?: string | null;
  signalOrigins: SourceSignalOrigin[];
};

export type SourceEvidence = {
  combinedText: string;
  transcriptText: string;
  captionText: string;
  ocrText: string;
  commentsText: string;
  explicitQuantityMentions: number;
  cueMentions: string[];
  hasStrongTranscript: boolean;
  hasAnyTextSignals: boolean;
  signalOriginCount: number;
  lowQualitySignalCount: number;
  actionVerbCount: number;
  titles: string[];
  creators: string[];
  thumbnailCandidates: string[];
};

export type CandidateIngredient = {
  id: string;
  name: string;
  quantity?: string | null;
  unit?: string | null;
  note?: string | null;
  confidence: number;
  uncertain?: boolean;
  supportingSignals: string[];
};

export type CandidateStep = {
  id: string;
  instruction: string;
  orderHint?: number | null;
  actionVerb?: string | null;
  object?: string | null;
  durationMinutes?: number | null;
  timestamp?: number | null;
  confidence: number;
  uncertain?: boolean;
  supportingSignals: string[];
};

export type CandidateMetadata = {
  titleCandidates: RankedTextCandidate[];
  creatorCandidates: RankedTextCandidate[];
  servings?: {
    value: number | null;
    confidence: number;
    supportingSignals: string[];
  };
  prepTimeMinutes?: {
    value: number | null;
    confidence: number;
    supportingSignals: string[];
  };
  cookTimeMinutes?: {
    value: number | null;
    confidence: number;
    supportingSignals: string[];
  };
  totalTimeMinutes?: {
    value: number | null;
    confidence: number;
    supportingSignals: string[];
  };
};

export type AggregatedEvidence = {
  ingredients: CandidateIngredient[];
  steps: CandidateStep[];
  metadata: CandidateMetadata;
  normalizedSignals: EvidenceSignal[];
};

export type ConfidenceReport = {
  score: number;
  warnings: string[];
  missingFields: string[];
  lowConfidenceAreas: string[];
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
  confidenceReport: ConfidenceReport;
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
  confidenceReport: ConfidenceReport;
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
