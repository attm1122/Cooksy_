import { detectPlatformFromUrl } from "@/features/recipes/lib/platform";
import type { RawRecipeContext, SourcePlatform } from "@/features/recipes/types";
import { captureError } from "@/lib/monitoring";
import type { ExtractionAdapter, ExtractionResult } from "./types";
import { youtubeAdapter } from "./youtube-adapter";
import { tiktokAdapter } from "./tiktok-adapter";
import { instagramAdapter } from "./instagram-adapter";
import { extractionCache, rateLimiter } from "./cache";
import { extractionAnalytics, recordExtractionResult } from "./analytics";

// Register all adapters
const adapters: ExtractionAdapter[] = [
  youtubeAdapter,
  tiktokAdapter,
  instagramAdapter
];

// Sort by priority (highest first)
adapters.sort((a, b) => b.priority - a.priority);

const getAllAdaptersForPlatform = (platform: SourcePlatform): ExtractionAdapter[] => {
  return adapters.filter(a => a.platforms.includes(platform));
};

export type ExtractionOptions = {
  useCache?: boolean;
  timeoutMs?: number;
  retryCount?: number;
  retryDelayMs?: number;
  forceFresh?: boolean;
};

const defaultOptions: ExtractionOptions = {
  useCache: true,
  timeoutMs: 30000,
  retryCount: 2,
  retryDelayMs: 1000,
  forceFresh: false
};

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Build a minimal fallback context when extraction fails
const buildFallbackContext = (url: string, platform: SourcePlatform): RawRecipeContext => ({
  sourceUrl: url,
  platform,
  title: null,
  creator: null,
  caption: null,
  transcript: null,
  thumbnailUrl: null,
  metadata: {
    extractionFailed: true,
    extractionSource: "fallback"
  }
});

const extractWithTimeout = async (
  adapter: ExtractionAdapter,
  url: string,
  platform: SourcePlatform,
  timeoutMs: number
): Promise<ExtractionResult> => {
  const timeoutPromise = new Promise<ExtractionResult>((_, reject) => {
    setTimeout(() => reject(new Error("Extraction timeout")), timeoutMs);
  });

  try {
    const result = await Promise.race([
      adapter.extract(url, platform),
      timeoutPromise
    ]);
    return result;
  } catch (error) {
    if (error instanceof Error && error.message === "Extraction timeout") {
      return {
        success: false,
        error: { type: "timeout", message: `Extraction timed out after ${timeoutMs}ms` }
      };
    }
    throw error;
  }
};

const attemptExtraction = async (
  url: string,
  platform: SourcePlatform,
  options: ExtractionOptions
): Promise<ExtractionResult> => {
  const adapters = getAllAdaptersForPlatform(platform);
  
  if (adapters.length === 0) {
    return {
      success: false,
      error: { type: "unsupported_url", message: `No extraction adapter for platform: ${platform}` }
    };
  }

  // Check rate limiting
  if (!rateLimiter.canProceed(platform)) {
    const waitTime = rateLimiter.getWaitTimeMs(platform);
    return {
      success: false,
      error: {
        type: "rate_limited",
        message: `Rate limit exceeded for ${platform}. Try again in ${Math.ceil(waitTime / 1000)}s.`,
        retryAfter: waitTime
      }
    };
  }

  rateLimiter.recordAttempt(platform);

  // Try each adapter in priority order
  const errors: string[] = [];
  
  for (const adapter of adapters) {
    for (let attempt = 0; attempt <= (options.retryCount || 0); attempt++) {
      try {
        const result = await extractWithTimeout(
          adapter,
          url,
          platform,
          options.timeoutMs || 30000
        );

        if (result.success) {
          return result;
        }

        // If not retryable or last attempt, record error
        if (!result.error || !("retryable" in result.error) || !result.error.retryable || attempt === options.retryCount) {
          errors.push(`${adapter.name}: ${result.error?.message || "Unknown error"}`);
          break;
        }

        // Wait before retry
        if (attempt < (options.retryCount || 0)) {
          await sleep(options.retryDelayMs || 1000);
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : "Unknown error";
        errors.push(`${adapter.name}: ${message}`);
        
        captureError(error, {
          action: "recipe_extraction",
          adapter: adapter.name,
          platform,
          attempt: attempt + 1
        });

        if (attempt < (options.retryCount || 0)) {
          await sleep(options.retryDelayMs || 1000);
        }
      }
    }
  }

  return {
    success: false,
    error: {
      type: "unknown",
      message: `All extraction attempts failed: ${errors.join("; ")}`
    },
    fallbackContext: buildFallbackContext(url, platform)
  };
};

/**
 * Extract recipe context from a URL
 * This is the main entry point for content extraction
 */
export const extractContextFromUrl = async (
  url: string,
  options: ExtractionOptions = {}
): Promise<ExtractionResult> => {
  const opts = { ...defaultOptions, ...options };
  const startTime = Date.now();
  
  try {
    const platform = detectPlatformFromUrl(url);

    // Check cache first
    if (opts.useCache && !opts.forceFresh) {
      const cached = extractionCache.get(url);
      if (cached) {
        const cachedResult: ExtractionResult = {
          success: true,
          context: cached,
          metadata: {
            extractionSource: "cache",
            durationMs: 0,
            signalCount: cached.transcriptSegments?.length || 0
          }
        };
        
        // Track cached result
        recordExtractionResult({
          url,
          platform,
          success: true,
          durationMs: 0,
          signalCount: cached.transcriptSegments?.length,
          extractionSource: "cache"
        });
        
        return cachedResult;
      }
    }

    const result = await attemptExtraction(url, platform, opts);
    const durationMs = Date.now() - startTime;

    // Cache successful results
    if (result.success && opts.useCache) {
      extractionCache.set(url, result.context);
    }

    // Track extraction result
    recordExtractionResult({
      url,
      platform,
      success: result.success,
      durationMs,
      error: result.success ? undefined : result.error,
      signalCount: result.success ? result.metadata.signalCount : undefined,
      extractionSource: result.success ? result.metadata.extractionSource : "failed"
    });

    return result;
  } catch (error) {
    captureError(error, { action: "extract_context", url });
    const durationMs = Date.now() - startTime;
    
    let platform: SourcePlatform = "youtube";
    try {
      platform = detectPlatformFromUrl(url);
    } catch {
      // Platform detection failed too
    }

    // Track error
    recordExtractionResult({
      url,
      platform,
      success: false,
      durationMs,
      error: { type: "unknown", message: error instanceof Error ? error.message : "Extraction failed" },
      extractionSource: "error"
    });

    return {
      success: false,
      error: {
        type: "unknown",
        message: error instanceof Error ? error.message : "Extraction failed"
      },
      fallbackContext: buildFallbackContext(url, platform)
    };
  }
};

/**
 * Extract context for multiple URLs in parallel
 */
export const extractMultipleContexts = async (
  urls: string[],
  options: ExtractionOptions = {}
): Promise<Map<string, ExtractionResult>> => {
  const results = new Map<string, ExtractionResult>();
  
  // Process in batches to avoid overwhelming rate limits
  const batchSize = 3;
  
  for (let i = 0; i < urls.length; i += batchSize) {
    const batch = urls.slice(i, i + batchSize);
    const batchResults = await Promise.all(
      batch.map(async url => {
        const result = await extractContextFromUrl(url, options);
        return { url, result };
      })
    );
    
    for (const { url, result } of batchResults) {
      results.set(url, result);
    }
    
    // Small delay between batches
    if (i + batchSize < urls.length) {
      await sleep(500);
    }
  }
  
  return results;
};

/**
 * Get extraction status for monitoring
 */
export const getExtractionStatus = () => ({
  cacheSize: (extractionCache as unknown as { size(): number }).size?.() || 0,
  rateLimits: {
    youtube: rateLimiter.getStatus("youtube"),
    tiktok: rateLimiter.getStatus("tiktok"),
    instagram: rateLimiter.getStatus("instagram")
  },
  adapters: adapters.map(a => ({
    name: a.name,
    platforms: a.platforms,
    priority: a.priority
  })),
  analytics: extractionAnalytics.getMetrics(),
  health: extractionAnalytics.getHealthStatus()
});

/**
 * Clear extraction cache
 */
export const clearExtractionCache = () => {
  extractionCache.clear();
};

export { extractionCache, rateLimiter };
