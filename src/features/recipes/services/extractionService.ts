import { detectPlatformFromUrl, parseInstagramUrl, parseTikTokUrl, parseYouTubeUrl } from "@/features/recipes/lib/platform";
import { ExtractionFailedError } from "@/features/recipes/lib/errors";
import { hydrateEvidenceContext } from "@/features/recipes/lib/sourceEvidence";
import { fetchSocialPageSignals } from "@/features/recipes/lib/socialSignals";
import { fetchYouTubeOEmbedMetadata, fetchYouTubeWatchPageSignals, getYouTubeThumbnailFromVideoId } from "@/features/recipes/lib/youtube";
import { getMockContextForUrl } from "@/features/recipes/mocks/sourceContexts";
import { getThumbnailFromContext } from "@/features/recipes/services/thumbnailService";
import { appEnv, hasSupabaseConfig } from "@/lib/env";
import { captureError, captureMessage } from "@/lib/monitoring";
import { extractContextFromUrl } from "@/features/recipes/extraction";
import type { RawRecipeContext, SourcePlatform } from "@/features/recipes/types";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// Determine if we should use real extraction or mock fallback
const shouldUseRealExtraction = (): boolean => {
  // Use real extraction in remote mode or when explicitly configured
  if (appEnv.recipeImportMode === "remote") return true;
  // In auto mode, use real extraction if Supabase is configured
  if (appEnv.recipeImportMode === "auto" && hasSupabaseConfig) return true;
  // Otherwise fall back to legacy behavior
  return false;
};

/**
 * Extract YouTube video context with transcript and metadata
 * Uses the new extraction adapter for real extraction
 */
export const extractYouTubeContext = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseYouTubeUrl(url);
  
  // Use new extraction layer if in production mode
  if (shouldUseRealExtraction()) {
    const result = await extractContextFromUrl(parsed.normalizedUrl, {
      timeoutMs: 20000,
      retryCount: 2
    });

    if (result.success) {
      return hydrateEvidenceContext(result.context);
    }

    // Log extraction failure but continue with fallback
    captureMessage("YouTube extraction failed, using fallback", {
      url: parsed.normalizedUrl,
      error: result.error?.message,
      type: result.error?.type
    });
  }

  // Legacy extraction as fallback
  return extractYouTubeContextLegacy(parsed.normalizedUrl);
};

/**
 * Legacy YouTube extraction for fallback
 */
const extractYouTubeContextLegacy = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseYouTubeUrl(url);
  await sleep(40);
  const mockContext = getMockContextForUrl(url, "youtube");

  try {
    const [oembed, watchSignals] = await Promise.all([
      fetchYouTubeOEmbedMetadata(parsed.normalizedUrl),
      fetchYouTubeWatchPageSignals(parsed.normalizedUrl).catch(() => null)
    ]);

    return hydrateEvidenceContext({
      ...mockContext,
      sourceUrl: parsed.normalizedUrl,
      platform: "youtube",
      title: oembed?.title ?? watchSignals?.title ?? mockContext.title,
      creator: oembed?.author_name ?? watchSignals?.creator ?? mockContext.creator,
      caption: watchSignals?.description ?? mockContext.caption,
      transcript: watchSignals?.transcript ?? mockContext.transcript,
      metadata: {
        ...(mockContext.metadata ?? {}),
        videoId: parsed.videoId,
        authorUrl: oembed?.author_url ?? null,
        watchSignalsAvailable: Boolean(watchSignals?.description || watchSignals?.transcript),
        captionTrackCount: watchSignals?.captionTracks?.length ?? 0,
        extractionSource: "legacy-fallback"
      },
      thumbnailUrl: oembed?.thumbnail_url ?? getYouTubeThumbnailFromVideoId(parsed.normalizedUrl) ?? getThumbnailFromContext(mockContext)
    });
  } catch (error) {
    if (!parsed.videoId) {
      throw new ExtractionFailedError("Cooksy could not extract a valid YouTube video id from this link");
    }

    captureError(error, { action: "youtube_legacy_extraction", url: parsed.normalizedUrl });
  }

  return hydrateEvidenceContext({
    ...mockContext,
    sourceUrl: parsed.normalizedUrl,
    platform: "youtube",
    metadata: {
      ...(mockContext.metadata ?? {}),
      videoId: parsed.videoId,
      extractionSource: "mock-fallback"
    },
    thumbnailUrl: getYouTubeThumbnailFromVideoId(parsed.normalizedUrl) ?? mockContext.thumbnailUrl ?? getThumbnailFromContext(mockContext)
  });
};

/**
 * Extract TikTok video context
 * Uses the new extraction adapter for real extraction
 */
export const extractTikTokContext = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseTikTokUrl(url);
  
  // Use new extraction layer if in production mode
  if (shouldUseRealExtraction()) {
    const result = await extractContextFromUrl(parsed.normalizedUrl, {
      timeoutMs: 20000,
      retryCount: 1
    });

    if (result.success) {
      return hydrateEvidenceContext(result.context);
    }

    // Log extraction failure
    captureMessage("TikTok extraction failed, using fallback", {
      url: parsed.normalizedUrl,
      error: result.error?.message
    });
  }

  // Legacy extraction as fallback
  return extractTikTokContextLegacy(parsed.normalizedUrl);
};

/**
 * Legacy TikTok extraction for fallback
 */
const extractTikTokContextLegacy = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseTikTokUrl(url);
  await sleep(40);
  const context = getMockContextForUrl(url, "tiktok");
  
  const allowClientSignalFetch = appEnv.recipeImportMode === "mock" || !hasSupabaseConfig;
  
  const signals = allowClientSignalFetch
    ? await fetchSocialPageSignals({
        sourceUrl: parsed.normalizedUrl,
        platform: "tiktok",
        creatorHint: parsed.creatorHandle
      }).catch(() => null)
    : null;

  return hydrateEvidenceContext({
    ...context,
    sourceUrl: parsed.normalizedUrl,
    platform: "tiktok",
    title: signals?.title ?? context.title,
    creator: signals?.creator ?? context.creator ?? parsed.creatorHandle ?? null,
    caption: signals?.description ?? context.caption,
    transcript: signals?.transcript ?? context.transcript,
    metadata: {
      ...(context.metadata ?? {}),
      videoId: parsed.videoId,
      creatorHandle: parsed.creatorHandle,
      signalOrigins: signals?.signalOrigins ?? ["mock-fallback"],
      extractionSource: signals?.signalOrigins?.includes("open-graph") ? "social-page" : "mock-fallback"
    },
    thumbnailUrl: signals?.thumbnailUrl ?? context.thumbnailUrl ?? getThumbnailFromContext(context)
  });
};

/**
 * Extract Instagram post/reel context
 * Uses the new extraction adapter for real extraction
 */
export const extractInstagramContext = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseInstagramUrl(url);
  
  // Use new extraction layer if in production mode
  if (shouldUseRealExtraction()) {
    const result = await extractContextFromUrl(parsed.normalizedUrl, {
      timeoutMs: 15000,
      retryCount: 1
    });

    if (result.success) {
      return hydrateEvidenceContext(result.context);
    }

    // Log extraction failure
    captureMessage("Instagram extraction failed, using fallback", {
      url: parsed.normalizedUrl,
      error: result.error?.message
    });
  }

  // Legacy extraction as fallback
  return extractInstagramContextLegacy(parsed.normalizedUrl);
};

/**
 * Legacy Instagram extraction for fallback
 */
const extractInstagramContextLegacy = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseInstagramUrl(url);
  await sleep(40);
  const context = getMockContextForUrl(url, "instagram");
  
  const allowClientSignalFetch = appEnv.recipeImportMode === "mock" || !hasSupabaseConfig;
  
  const signals = allowClientSignalFetch
    ? await fetchSocialPageSignals({
        sourceUrl: parsed.normalizedUrl,
        platform: "instagram"
      }).catch(() => null)
    : null;

  return hydrateEvidenceContext({
    ...context,
    sourceUrl: parsed.normalizedUrl,
    platform: "instagram",
    title: signals?.title ?? context.title,
    creator: signals?.creator ?? context.creator,
    caption: signals?.description ?? context.caption,
    transcript: signals?.transcript ?? context.transcript,
    metadata: {
      ...(context.metadata ?? {}),
      mediaCode: parsed.mediaCode,
      signalOrigins: signals?.signalOrigins ?? ["mock-fallback"],
      extractionSource: signals?.signalOrigins?.includes("open-graph") ? "social-page" : "mock-fallback"
    },
    thumbnailUrl: signals?.thumbnailUrl ?? context.thumbnailUrl ?? getThumbnailFromContext(context)
  });
};

/**
 * Main entry point for recipe context extraction
 * Routes to the appropriate platform-specific extractor
 */
export const extractRecipeContextFromUrl = async (url: string): Promise<RawRecipeContext> => {
  const platform = detectPlatformFromUrl(url);

  if (platform === "youtube") {
    return extractYouTubeContext(url);
  }

  if (platform === "tiktok") {
    return extractTikTokContext(url);
  }

  if (platform === "instagram") {
    return extractInstagramContext(url);
  }

  throw new ExtractionFailedError();
};

/**
 * Batch extract multiple URLs
 * Useful for processing multiple imports
 */
export const extractMultipleContexts = async (
  urls: string[]
): Promise<Array<{ url: string; context: RawRecipeContext; success: boolean; error?: string }>> => {
  const results = await Promise.all(
    urls.map(async (url) => {
      try {
        const context = await extractRecipeContextFromUrl(url);
        return { url, context, success: true };
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : "Extraction failed";
        captureError(error, { action: "batch_extraction", url });
        
        // Return fallback context on error
        let platform: SourcePlatform = "youtube";
        try {
          platform = detectPlatformFromUrl(url);
        } catch {
          // Ignore
        }
        
        return {
          url,
          context: {
            sourceUrl: url,
            platform,
            title: null,
            creator: null,
            metadata: { extractionFailed: true }
          } as RawRecipeContext,
          success: false,
          error: errorMessage
        };
      }
    })
  );
  
  return results;
};
