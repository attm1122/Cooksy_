import { parseInstagramUrl, parseTikTokUrl, parseYouTubeUrl } from "@/features/recipes/lib/platform";
import type { RawRecipeContext, Recipe, SourcePlatform, ThumbnailSource } from "@/features/recipes/types";
import type { Recipe as UiRecipe } from "@/types/recipe";

export type ThumbnailResult = {
  thumbnailUrl: string | null;
  thumbnailSource: ThumbnailSource;
  thumbnailFallbackStyle?: string;
  isLowQuality?: boolean;
};

const fallbackStyles = ["golden-sear", "paprika-glow", "toast-cream", "copper-pan"] as const;

const pickFallbackStyle = (seed: string) => {
  const total = seed.split("").reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return fallbackStyles[total % fallbackStyles.length];
};

const buildTikTokThumbnailUrl = (url: string) => {
  const parsed = parseTikTokUrl(url);
  const seed = parsed.videoId ?? parsed.creatorHandle ?? "cooksy";
  return `https://picsum.photos/seed/tiktok-${seed}/1280/960`;
};

const buildInstagramThumbnailUrl = (url: string) => {
  const parsed = parseInstagramUrl(url);
  const seed = parsed.mediaCode ?? "cooksy";
  return `https://picsum.photos/seed/instagram-${seed}/1280/960`;
};

export const generateFallbackThumbnailStyle = (recipeTitle: string, platform: string) =>
  pickFallbackStyle(`${recipeTitle}-${platform}`);

const inferDimensionsFromUrl = (url: string) => {
  if (/maxresdefault/.test(url)) {
    return { width: 1280, height: 720 };
  }

  if (/hqdefault/.test(url)) {
    return { width: 480, height: 360 };
  }

  const match = url.match(/\/(\d{3,4})\/(\d{3,4})(?:$|[/?#])/);
  if (!match) {
    return null;
  }

  return {
    width: Number(match[1]),
    height: Number(match[2])
  };
};

const scoreThumbnailCandidate = (url: string, platform?: SourcePlatform) => {
  const dimensions = inferDimensionsFromUrl(url);
  const pixelScore = dimensions ? Math.min(60, (dimensions.width * dimensions.height) / 40000) : 18;
  const aspectRatio = dimensions ? dimensions.width / dimensions.height : 1.33;
  const aspectScore = Math.max(0, 24 - Math.abs(aspectRatio - 1.45) * 30);
  const platformScore =
    platform && url.toLowerCase().includes(platform === "youtube" ? "ytimg" : platform === "tiktok" ? "tiktok" : "instagram") ? 12 : 0;
  const canonicalScore = /maxresdefault|hqdefault|cdn\./i.test(url) ? 14 : 0;

  return pixelScore + aspectScore + platformScore + canonicalScore;
};

export const selectBestThumbnailCandidate = (candidates: string[], platform?: SourcePlatform) => {
  const uniqueCandidates = Array.from(new Set(candidates.filter(Boolean)));

  if (!uniqueCandidates.length) {
    return null;
  }

  return uniqueCandidates.sort((left, right) => scoreThumbnailCandidate(right, platform) - scoreThumbnailCandidate(left, platform))[0] ?? null;
};

export const getThumbnailFromContext = (context: RawRecipeContext): string | null => {
  const fallbackCandidates = [
    context.thumbnailUrl ?? null,
    ...(context.thumbnailCandidates ?? []),
    context.platform === "youtube"
      ? (() => {
          const parsed = parseYouTubeUrl(context.sourceUrl);
          return parsed.videoId
            ? parsed.videoId.length === 11
              ? `https://img.youtube.com/vi/${parsed.videoId}/hqdefault.jpg`
              : `https://picsum.photos/seed/youtube-${parsed.videoId}/1280/720`
            : null;
        })()
      : context.platform === "tiktok"
        ? buildTikTokThumbnailUrl(context.sourceUrl)
        : buildInstagramThumbnailUrl(context.sourceUrl)
  ].filter((candidate): candidate is string => Boolean(candidate));

  return selectBestThumbnailCandidate(fallbackCandidates, context.platform);
};

const inferPlatform = (url: string): SourcePlatform => {
  if (url.includes("tiktok")) {
    return "tiktok";
  }

  if (url.includes("instagram")) {
    return "instagram";
  }

  return "youtube";
};

export const generateFallbackThumbnail = (recipe: Recipe | UiRecipe) =>
  recipe.thumbnailFallbackStyle ??
  generateFallbackThumbnailStyle(
    recipe.title,
    "sourcePlatform" in recipe ? recipe.sourcePlatform : recipe.source.platform
  );

export const getThumbnailFromUrl = async (url: string): Promise<ThumbnailResult> => {
  const platform = inferPlatform(url);
  const fallbackStyle = pickFallbackStyle(url);

  if (platform === "youtube") {
    const parsed = parseYouTubeUrl(url);

    if (!parsed.videoId) {
      return {
        thumbnailUrl: `https://picsum.photos/seed/youtube-fallback-${encodeURIComponent(url)}/1280/720`,
        thumbnailSource: "youtube",
        thumbnailFallbackStyle: fallbackStyle,
        isLowQuality: true
      };
    }

    return {
      thumbnailUrl:
        parsed.videoId.length === 11
          ? `https://img.youtube.com/vi/${parsed.videoId}/hqdefault.jpg`
          : `https://picsum.photos/seed/youtube-${parsed.videoId}/1280/720`,
      thumbnailSource: "youtube",
      thumbnailFallbackStyle: fallbackStyle
    };
  }

  if (platform === "tiktok") {
    return {
      thumbnailUrl: buildTikTokThumbnailUrl(url),
      thumbnailSource: "tiktok",
      thumbnailFallbackStyle: fallbackStyle
    };
  }

  return {
    thumbnailUrl: buildInstagramThumbnailUrl(url),
    thumbnailSource: "instagram",
    thumbnailFallbackStyle: fallbackStyle
  };
};
