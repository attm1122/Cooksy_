import type { Recipe, SourcePlatform, ThumbnailSource } from "@/types/recipe";

export type ThumbnailResult = {
  thumbnailUrl: string | null;
  thumbnailSource: ThumbnailSource;
  thumbnailFallbackStyle?: string;
  isLowQuality?: boolean;
};

const fallbackStyles = ["golden-sear", "paprika-glow", "toast-cream", "copper-pan"] as const;

const extractYouTubeVideoId = (url: string) => {
  const watchMatch = url.match(/[?&]v=([^&]+)/);
  if (watchMatch?.[1]) {
    return watchMatch[1];
  }

  const shortMatch = url.match(/youtu\.be\/([^?&/]+)/);
  if (shortMatch?.[1]) {
    return shortMatch[1];
  }

  return null;
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

const pickFallbackStyle = (seed: string) => {
  const total = seed.split("").reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return fallbackStyles[total % fallbackStyles.length];
};

const buildTikTokThumbnailUrl = (url: string) => {
  const videoMatch = url.match(/video\/(\d+)/);
  const creatorMatch = url.match(/@([^/]+)/);
  const seed = videoMatch?.[1] ?? creatorMatch?.[1] ?? "cooksy";

  return `https://picsum.photos/seed/tiktok-${seed}/1280/960`;
};

const buildInstagramThumbnailUrl = (url: string) => {
  const reelMatch = url.match(/reel\/([^/?]+)/);
  const postMatch = url.match(/p\/([^/?]+)/);
  const seed = reelMatch?.[1] ?? postMatch?.[1] ?? "cooksy";

  return `https://picsum.photos/seed/instagram-${seed}/1280/960`;
};

export const generateFallbackThumbnail = (recipe: Recipe) =>
  recipe.thumbnailFallbackStyle ?? pickFallbackStyle(`${recipe.id}-${recipe.title}-${recipe.source.platform}`);

export const getThumbnailFromUrl = async (url: string): Promise<ThumbnailResult> => {
  const platform = inferPlatform(url);
  const fallbackStyle = pickFallbackStyle(url);

  if (platform === "youtube") {
    const videoId = extractYouTubeVideoId(url);

    if (!videoId) {
      return {
        thumbnailUrl: `https://picsum.photos/seed/youtube-fallback-${encodeURIComponent(url)}/1280/720`,
        thumbnailSource: "youtube",
        thumbnailFallbackStyle: fallbackStyle,
        isLowQuality: true
      };
    }

    return {
      thumbnailUrl:
        videoId.length === 11
          ? `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`
          : `https://picsum.photos/seed/youtube-${videoId}/1280/720`,
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
