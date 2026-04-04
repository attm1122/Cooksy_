import type {
  ParsedInstagramUrl,
  ParsedRecipeUrl,
  ParsedTikTokUrl,
  ParsedYouTubeUrl,
  SourcePlatform
} from "@/features/recipes/types";
import { InvalidRecipeUrlError, UnsupportedPlatformError } from "@/features/recipes/lib/errors";

const normalizeUrl = (value: string) => {
  try {
    const url = new URL(value);
    return url;
  } catch {
    throw new InvalidRecipeUrlError();
  }
};

const normalizeHost = (hostname: string) => hostname.toLowerCase().replace(/^www\./, "");

export const parseYouTubeUrl = (value: string): ParsedYouTubeUrl => {
  const url = normalizeUrl(value);
  const host = normalizeHost(url.hostname);
  const path = url.pathname.toLowerCase();

  if (!["youtube.com", "m.youtube.com", "youtu.be"].includes(host)) {
    throw new UnsupportedPlatformError();
  }

  const videoId =
    host === "youtu.be"
      ? path.split("/").filter(Boolean)[0] ?? null
      : url.searchParams.get("v") ??
        path.split("/shorts/")[1]?.split("/")[0] ??
        path.split("/live/")[1]?.split("/")[0] ??
        null;

  return {
    platform: "youtube",
    normalizedUrl: url.toString(),
    videoId
  };
};

export const parseTikTokUrl = (value: string): ParsedTikTokUrl => {
  const url = normalizeUrl(value);
  const host = normalizeHost(url.hostname);
  const path = url.pathname;

  if (!["tiktok.com", "m.tiktok.com", "vm.tiktok.com"].includes(host)) {
    throw new UnsupportedPlatformError();
  }

  const creatorHandle = path.match(/@([^/]+)/)?.[1] ?? null;
  const videoId = path.match(/video\/(\d+)/)?.[1] ?? path.split("/t/")[1]?.split("/")[0] ?? null;

  return {
    platform: "tiktok",
    normalizedUrl: url.toString(),
    creatorHandle,
    videoId
  };
};

export const parseInstagramUrl = (value: string): ParsedInstagramUrl => {
  const url = normalizeUrl(value);
  const host = normalizeHost(url.hostname);
  const path = url.pathname;

  if (host !== "instagram.com") {
    throw new UnsupportedPlatformError();
  }

  const mediaCode =
    path.split("/reel/")[1]?.split("/")[0] ??
    path.split("/p/")[1]?.split("/")[0] ??
    path.split("/tv/")[1]?.split("/")[0] ??
    null;

  return {
    platform: "instagram",
    normalizedUrl: url.toString(),
    mediaCode
  };
};

export const detectPlatformFromUrl = (value: string): SourcePlatform => {
  const url = normalizeUrl(value);
  const host = normalizeHost(url.hostname);
  const path = url.pathname.toLowerCase();

  if (host === "youtu.be" && path.length > 1) {
    return "youtube";
  }

  if (["youtube.com", "m.youtube.com"].includes(host)) {
    if ((path.startsWith("/watch") && url.searchParams.get("v")) || path.startsWith("/shorts/") || path.startsWith("/live/")) {
      return "youtube";
    }
  }

  if (["tiktok.com", "m.tiktok.com", "vm.tiktok.com"].includes(host) && (path.includes("/video/") || path.startsWith("/t/"))) {
    return "tiktok";
  }

  if (host === "instagram.com" && (path.startsWith("/reel/") || path.startsWith("/p/") || path.startsWith("/tv/"))) {
    return "instagram";
  }

  throw new UnsupportedPlatformError();
};

export const parseRecipeUrl = (value: string): ParsedRecipeUrl => {
  const platform = detectPlatformFromUrl(value);

  if (platform === "youtube") {
    return parseYouTubeUrl(value);
  }

  if (platform === "tiktok") {
    return parseTikTokUrl(value);
  }

  return parseInstagramUrl(value);
};

