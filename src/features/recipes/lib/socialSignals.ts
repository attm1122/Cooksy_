import type { SourcePlatform, SourceSignals } from "@/features/recipes/types";

const decodeHtmlEntities = (value: string) =>
  value
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");

const collapseWhitespace = (value: string) => value.replace(/\s+/g, " ").trim();

const extractMetaContent = (html: string, attribute: "property" | "name", key: string) => {
  const pattern = new RegExp(`<meta[^>]+${attribute}=["']${key}["'][^>]+content=["']([^"']+)["'][^>]*>`, "i");
  const reversePattern = new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+${attribute}=["']${key}["'][^>]*>`, "i");
  const match = html.match(pattern) ?? html.match(reversePattern);

  return match?.[1] ? collapseWhitespace(decodeHtmlEntities(match[1])) : null;
};

const extractJsonLdBlocks = (html: string) =>
  Array.from(html.matchAll(/<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi))
    .map((match) => match[1]?.trim())
    .filter((value): value is string => Boolean(value));

const parseJsonLdCandidate = (input: string): Record<string, unknown>[] => {
  try {
    const parsed = JSON.parse(input) as unknown;

    if (Array.isArray(parsed)) {
      return parsed.filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === "object");
    }

    if (parsed && typeof parsed === "object") {
      return [parsed as Record<string, unknown>];
    }
  } catch {
    return [];
  }

  return [];
};

const extractCreatorFromJsonLd = (html: string) => {
  for (const block of extractJsonLdBlocks(html)) {
    for (const candidate of parseJsonLdCandidate(block)) {
      const author = candidate.author;

      if (author && typeof author === "object" && typeof (author as { name?: unknown }).name === "string") {
        return collapseWhitespace(String((author as { name: string }).name));
      }

      if (typeof candidate.creator === "string") {
        return collapseWhitespace(candidate.creator);
      }
    }
  }

  return null;
};

const deriveCreatorFallback = (html: string, platform: SourcePlatform, creatorHint?: string | null) => {
  if (creatorHint) {
    return creatorHint;
  }

  if (platform === "tiktok") {
    const handleMatch = html.match(/@([a-z0-9._]+)/i);
    return handleMatch ? `@${handleMatch[1]}` : null;
  }

  if (platform === "instagram") {
    const match = html.match(/by\s+([A-Za-z0-9._]+)/i);
    return match ? match[1] : null;
  }

  return null;
};

export const fetchSocialPageSignals = async ({
  sourceUrl,
  platform,
  creatorHint
}: {
  sourceUrl: string;
  platform: SourcePlatform;
  creatorHint?: string | null;
}): Promise<SourceSignals> => {
  const response = await fetch(sourceUrl);

  if (!response.ok) {
    return {
      signalOrigins: ["mock-fallback"]
    };
  }

  const html = await response.text();
  const title =
    extractMetaContent(html, "property", "og:title") ??
    extractMetaContent(html, "name", "twitter:title");
  const description =
    extractMetaContent(html, "property", "og:description") ??
    extractMetaContent(html, "name", "twitter:description");
  const thumbnailUrl =
    extractMetaContent(html, "property", "og:image") ??
    extractMetaContent(html, "name", "twitter:image");
  const jsonLdCreator = extractCreatorFromJsonLd(html);
  const creator =
    extractMetaContent(html, "name", "author") ??
    jsonLdCreator ??
    deriveCreatorFallback(html, platform, creatorHint);

  const signalOrigins: SourceSignals["signalOrigins"] = [];

  if (title || description || thumbnailUrl) {
    signalOrigins.push("open-graph");
  }

  if (jsonLdCreator) {
    signalOrigins.push("json-ld");
  }

  if (!signalOrigins.length) {
    signalOrigins.push("mock-fallback");
  }

  return {
    title,
    description,
    creator,
    thumbnailUrl,
    transcript: description ?? null,
    signalOrigins
  };
};
