import type { SourcePlatform } from "@/types/recipe";

const YOUTUBE_HOSTS = new Set(["youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be"]);
const TIKTOK_HOSTS = new Set(["tiktok.com", "www.tiktok.com", "m.tiktok.com", "vm.tiktok.com"]);
const INSTAGRAM_HOSTS = new Set(["instagram.com", "www.instagram.com"]);

const normalizeHost = (hostname: string) => hostname.toLowerCase().replace(/^www\./, "");

export const getSupportedPlatformFromUrl = (value: string): SourcePlatform | null => {
  try {
    const url = new URL(value);
    const host = normalizeHost(url.hostname);
    const path = url.pathname.toLowerCase();

    if (YOUTUBE_HOSTS.has(host) || host === "youtu.be") {
      if (host === "youtu.be" && path.length > 1) {
        return "youtube";
      }

      if (path.startsWith("/watch") && url.searchParams.get("v")) {
        return "youtube";
      }

      if (path.startsWith("/shorts/") || path.startsWith("/live/")) {
        return "youtube";
      }
    }

    if (TIKTOK_HOSTS.has(host) && (path.includes("/video/") || path.startsWith("/t/"))) {
      return "tiktok";
    }

    if (INSTAGRAM_HOSTS.has(host) && (path.startsWith("/reel/") || path.startsWith("/p/") || path.startsWith("/tv/"))) {
      return "instagram";
    }
  } catch {
    return null;
  }

  return null;
};

export const isSupportedSourceUrl = (value: string) => getSupportedPlatformFromUrl(value) !== null;
