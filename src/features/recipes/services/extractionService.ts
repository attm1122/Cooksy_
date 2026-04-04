import { detectPlatformFromUrl, parseInstagramUrl, parseTikTokUrl, parseYouTubeUrl } from "@/features/recipes/lib/platform";
import { ExtractionFailedError } from "@/features/recipes/lib/errors";
import { getMockContextForUrl } from "@/features/recipes/mocks/sourceContexts";
import { getThumbnailFromContext } from "@/features/recipes/services/thumbnailService";
import type { RawRecipeContext } from "@/features/recipes/types";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export const extractYouTubeContext = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseYouTubeUrl(url);
  await sleep(40);
  const context = getMockContextForUrl(url, "youtube");

  return {
    ...context,
    sourceUrl: parsed.normalizedUrl,
    platform: "youtube",
    metadata: {
      ...(context.metadata ?? {}),
      videoId: parsed.videoId
    },
    thumbnailUrl: context.thumbnailUrl ?? getThumbnailFromContext(context)
  };
};

export const extractTikTokContext = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseTikTokUrl(url);
  await sleep(40);
  const context = getMockContextForUrl(url, "tiktok");

  return {
    ...context,
    sourceUrl: parsed.normalizedUrl,
    platform: "tiktok",
    creator: context.creator ?? parsed.creatorHandle ?? null,
    metadata: {
      ...(context.metadata ?? {}),
      videoId: parsed.videoId,
      creatorHandle: parsed.creatorHandle
    },
    thumbnailUrl: context.thumbnailUrl ?? getThumbnailFromContext(context)
  };
};

export const extractInstagramContext = async (url: string): Promise<RawRecipeContext> => {
  const parsed = parseInstagramUrl(url);
  await sleep(40);
  const context = getMockContextForUrl(url, "instagram");

  return {
    ...context,
    sourceUrl: parsed.normalizedUrl,
    platform: "instagram",
    metadata: {
      ...(context.metadata ?? {}),
      mediaCode: parsed.mediaCode
    },
    thumbnailUrl: context.thumbnailUrl ?? getThumbnailFromContext(context)
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

