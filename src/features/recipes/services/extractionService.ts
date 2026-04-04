import { detectPlatformFromUrl, parseInstagramUrl, parseTikTokUrl, parseYouTubeUrl } from "@/features/recipes/lib/platform";
import { ExtractionFailedError } from "@/features/recipes/lib/errors";
import { fetchSocialPageSignals } from "@/features/recipes/lib/socialSignals";
import { fetchYouTubeOEmbedMetadata, fetchYouTubeWatchPageSignals, getYouTubeThumbnailFromVideoId } from "@/features/recipes/lib/youtube";
import { getMockContextForUrl } from "@/features/recipes/mocks/sourceContexts";
import { getThumbnailFromContext } from "@/features/recipes/services/thumbnailService";
import { appEnv, hasSupabaseConfig } from "@/lib/env";
import type { RawRecipeContext } from "@/features/recipes/types";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
const allowClientSignalFetch = appEnv.recipeImportMode === "mock" || !hasSupabaseConfig;

export const extractYouTubeContext = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseYouTubeUrl(url);
  await sleep(40);
  const mockContext = getMockContextForUrl(url, "youtube");

  if (!allowClientSignalFetch) {
    return {
      ...mockContext,
      sourceUrl: parsed.normalizedUrl,
      platform: "youtube",
      metadata: {
        ...(mockContext.metadata ?? {}),
        videoId: parsed.videoId,
        extractionSource: "mock-fallback"
      },
      thumbnailUrl: getYouTubeThumbnailFromVideoId(parsed.normalizedUrl) ?? mockContext.thumbnailUrl ?? getThumbnailFromContext(mockContext)
    };
  }

  try {
    const [oembed, watchSignals] = await Promise.all([
      fetchYouTubeOEmbedMetadata(parsed.normalizedUrl),
      fetchYouTubeWatchPageSignals(parsed.normalizedUrl).catch(() => null)
    ]);

    return {
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
        extractionSource:
          oembed && (watchSignals?.description || watchSignals?.transcript)
            ? "youtube-oembed+watch"
            : oembed
              ? "youtube-oembed"
              : watchSignals?.description || watchSignals?.transcript
                ? "youtube-watch"
                : "mock-fallback"
      },
      thumbnailUrl: oembed?.thumbnail_url ?? getYouTubeThumbnailFromVideoId(parsed.normalizedUrl) ?? getThumbnailFromContext(mockContext)
    };
  } catch {
    if (!parsed.videoId) {
      throw new ExtractionFailedError("Cooksy could not extract a valid YouTube video id from this link");
    }
  }

  return {
    ...mockContext,
    sourceUrl: parsed.normalizedUrl,
    platform: "youtube",
    metadata: {
      ...(mockContext.metadata ?? {}),
      videoId: parsed.videoId,
      extractionSource: "mock-fallback"
    },
    thumbnailUrl: getYouTubeThumbnailFromVideoId(parsed.normalizedUrl) ?? mockContext.thumbnailUrl ?? getThumbnailFromContext(mockContext)
  };
};

export const extractTikTokContext = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseTikTokUrl(url);
  await sleep(40);
  const context = getMockContextForUrl(url, "tiktok");
  const signals = allowClientSignalFetch
    ? await fetchSocialPageSignals({
        sourceUrl: parsed.normalizedUrl,
        platform: "tiktok",
        creatorHint: parsed.creatorHandle
      }).catch(() => null)
    : null;

  return {
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
      extractionSource: signals?.signalOrigins?.includes("open-graph") || signals?.signalOrigins?.includes("json-ld") ? "social-page" : "mock-fallback"
    },
    thumbnailUrl: signals?.thumbnailUrl ?? context.thumbnailUrl ?? getThumbnailFromContext(context)
  };
};

export const extractInstagramContext = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseInstagramUrl(url);
  await sleep(40);
  const context = getMockContextForUrl(url, "instagram");
  const signals = allowClientSignalFetch
    ? await fetchSocialPageSignals({
        sourceUrl: parsed.normalizedUrl,
        platform: "instagram"
      }).catch(() => null)
    : null;

  return {
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
      extractionSource: signals?.signalOrigins?.includes("open-graph") || signals?.signalOrigins?.includes("json-ld") ? "social-page" : "mock-fallback"
    },
    thumbnailUrl: signals?.thumbnailUrl ?? context.thumbnailUrl ?? getThumbnailFromContext(context)
  };
};

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
