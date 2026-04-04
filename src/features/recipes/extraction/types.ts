import type { RawRecipeContext, SourcePlatform } from "@/features/recipes/types";

export type ExtractionResult = {
  success: true;
  context: RawRecipeContext;
  metadata: {
    extractionSource: string;
    durationMs: number;
    signalCount: number;
  };
} | {
  success: false;
  error: ExtractionError;
  fallbackContext?: RawRecipeContext;
};

export type ExtractionError = 
  | { type: "unsupported_url"; message: string }
  | { type: "network_error"; message: string; retryable: boolean }
  | { type: "rate_limited"; message: string; retryAfter?: number }
  | { type: "content_unavailable"; message: string }
  | { type: "parsing_error"; message: string }
  | { type: "timeout"; message: string }
  | { type: "unknown"; message: string };

export type ExtractionAdapter = {
  name: string;
  platforms: SourcePlatform[];
  priority: number; // Higher = preferred
  extract: (url: string, platform: SourcePlatform) => Promise<ExtractionResult>;
};

export type CacheEntry = {
  url: string;
  context: RawRecipeContext;
  timestamp: number;
  ttlMs: number;
};

export type ExtractionCache = {
  get: (url: string) => RawRecipeContext | undefined;
  set: (url: string, context: RawRecipeContext, ttlMs?: number) => void;
  clear: () => void;
};

export type RateLimiter = {
  canProceed: (platform: SourcePlatform) => boolean;
  recordAttempt: (platform: SourcePlatform) => void;
  getWaitTimeMs: (platform: SourcePlatform) => number;
};
