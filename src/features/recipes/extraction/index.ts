// Main extraction exports
export {
  extractContextFromUrl,
  extractMultipleContexts,
  getExtractionStatus,
  clearExtractionCache,
  extractionCache,
  rateLimiter,
  type ExtractionOptions
} from "./orchestrator";

// Adapter exports
export { youtubeAdapter, extractYouTubeContext } from "./youtube-adapter";
export { tiktokAdapter, extractTikTokContext } from "./tiktok-adapter";
export { instagramAdapter, extractInstagramContext } from "./instagram-adapter";

// Type exports
export type {
  ExtractionAdapter,
  ExtractionResult,
  ExtractionError,
  ExtractionCache,
  CacheEntry,
  RateLimiter
} from "./types";

// Analytics exports
export {
  extractionAnalytics,
  recordExtractionResult,
  type ExtractionMetrics
} from "./analytics";

// Whisper transcription exports
export {
  transcribeWithWhisper,
  transcribeYouTubeVideo,
  mockWhisperTranscription,
  isWhisperAvailable,
  type WhisperTranscriptionResult
} from "./whisper-transcription";

// Background jobs exports
export {
  backgroundJobProcessor,
  queueExtraction,
  waitForJobCompletion,
  type JobStatus,
  type ExtractionJob
} from "./background-jobs";
