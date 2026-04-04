import { appEnv } from "@/lib/env";
import { parseTikTokUrl } from "@/features/recipes/lib/platform";
import type { RawRecipeContext, TranscriptSegment } from "@/features/recipes/types";
import type { ExtractionAdapter, ExtractionResult } from "./types";

const decodeHtmlEntities = (value: string) =>
  value
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");

const collapseWhitespace = (value: string) => value.replace(/\s+/g, " ").trim();

// Extract metadata from TikTok's embedded JSON data
const extractTikTokMetadata = (html: string) => {
  const patterns = {
    // Look for SSR data or embedded script
    ssrData: /<script[^>]*>window\._SSR_HYDRATED_DATA\s*=\s*({.*?})<\/script>/s,
    // General metadata patterns
    title: [/<meta[^>]*property="og:title"[^>]*content="([^"]+)"/i, /<title>([^<]+)<\/title>/i],
    description: [/<meta[^>]*property="og:description"[^>]*content="([^"]+)"/i],
    creator: [/<meta[^>]*property="og:creator"[^>]*content="([^"]+)"/i, /"uniqueId":"([^"]+)"/],
    thumbnail: [/<meta[^>]*property="og:image"[^>]*content="([^"]+)"/i],
    videoUrl: [/<meta[^>]*property="og:video"[^>]*content="([^"]+)"/i]
  };

  const extract = (patternList: RegExp[]): string | null => {
    for (const pattern of patternList) {
      const match = html.match(pattern);
      if (match?.[1]) return decodeHtmlEntities(match[1]);
    }
    return null;
  };

  // Try SSR data first
  const ssrMatch = html.match(patterns.ssrData);
  let ssrData: Record<string, unknown> | null = null;
  
  if (ssrMatch?.[1]) {
    try {
      ssrData = JSON.parse(ssrMatch[1].replace(/undefined/g, "null"));
    } catch {
      // Failed to parse SSR data
    }
  }

  // Extract from SSR if available
  const itemInfo = ssrData?.ItemModule ? Object.values(ssrData.ItemModule as Record<string, unknown>)[0] as Record<string, unknown> : null;
  
  const description = itemInfo?.desc as string || extract(patterns.description);
  // Parse caption segments from description (TikTok captions often have timestamps)
  const captionSegments: TranscriptSegment[] = [];
  if (description) {
    // Split by common delimiters and create segments
    const parts = description.split(/[.!?]+/).filter(s => s.trim().length > 10);
    parts.forEach((part, idx) => {
      captionSegments.push({
        id: `tt-caption-${idx}`,
        text: collapseWhitespace(part),
        startSeconds: idx * 5 // Estimate 5 seconds per segment
      });
    });
  }

  return {
    title: extract(patterns.title),
    creator: itemInfo?.author as string || extract(patterns.creator),
    description,
    thumbnail: extract(patterns.thumbnail),
    videoUrl: extract(patterns.videoUrl),
    captionSegments,
    // Extract any on-screen text hints from description
    ocrHints: description ? extractOcrHintsFromDescription(description) : []
  };
};

// Try to identify ingredient/step patterns in description
const extractOcrHintsFromDescription = (description: string): string[] => {
  const hints: string[] = [];
  
  // Look for recipe patterns like "Ingredients:", "Steps:", etc.
  const lines = description.split(/\n|\\n/);
  
  for (const line of lines) {
    const trimmed = line.trim();
    // Look for numbered steps
    if (/^\d+[.):\s]+/.test(trimmed) && trimmed.length > 15) {
      hints.push(trimmed.replace(/^\d+[.):\s]+/, "").trim());
    }
    // Look for ingredient patterns (quantity + ingredient)
    if (/\b\d+\s*(?:cups?|tbsp|tsp|oz|lbs?|g|kg|ml|pieces?|cloves?)\b/i.test(trimmed)) {
      hints.push(trimmed);
    }
  }
  
  return hints;
};

const scrapeTikTokPage = async (url: string) => {
  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
        "Accept-Encoding": "gzip, deflate, br",
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1"
      },
      signal: AbortSignal.timeout(15000)
    });

    if (!response.ok) {
      if (response.status === 403) {
        return { blocked: true, html: null };
      }
      return { blocked: false, html: null };
    }

    return { blocked: false, html: await response.text() };
  } catch (error) {
    const isTimeout = error instanceof Error && error.name === "TimeoutError";
    return { blocked: false, html: null, timeout: isTimeout };
  }
};

// Use RapidAPI as fallback for TikTok
const fetchFromRapidApi = async (videoId: string): Promise<Partial<RawRecipeContext> | null> => {
  if (!appEnv.rapidApiKey || !appEnv.rapidApiHost) {
    return null;
  }

  try {
    const response = await fetch(`https://${appEnv.rapidApiHost}/video/info?video_id=${videoId}`, {
      method: "GET",
      headers: {
        "X-RapidAPI-Key": appEnv.rapidApiKey,
        "X-RapidAPI-Host": appEnv.rapidApiHost
      },
      signal: AbortSignal.timeout(10000)
    });

    if (!response.ok) return null;

    const data = await response.json() as {
      title?: string;
      description?: string;
      author?: { unique_id?: string; nickname?: string };
      cover?: string;
      video?: { duration?: number };
    };

    return {
      title: data.title,
      caption: data.description,
      creator: data.author?.nickname || data.author?.unique_id,
      thumbnailUrl: data.cover
    };
  } catch {
    return null;
  }
};

export const extractTikTokContext = async (sourceUrl: string): Promise<ExtractionResult> => {
  const startTime = Date.now();
  const parsed = parseTikTokUrl(sourceUrl);

  if (!parsed.videoId) {
    return {
      success: false,
      error: { type: "unsupported_url", message: "Could not extract TikTok video ID" }
    };
  }

  let metadata: ReturnType<typeof extractTikTokMetadata> | null = null;
  let extractionSource = "tiktok-scrape";
  let wasBlocked = false;

  // Try scraping if enabled
  if (appEnv.enableTikTokScraping) {
    const scrapeResult = await scrapeTikTokPage(parsed.normalizedUrl);
    
    if (scrapeResult.blocked) {
      wasBlocked = true;
    } else if (scrapeResult.html) {
      metadata = extractTikTokMetadata(scrapeResult.html);
    }
  }

  // Fall back to RapidAPI if scraping failed or is disabled
  if (!metadata && appEnv.rapidApiKey) {
    const apiData = await fetchFromRapidApi(parsed.videoId);
    if (apiData) {
      extractionSource = "tiktok-rapidapi";
      metadata = {
        title: apiData.title || null,
        creator: apiData.creator || null,
        description: apiData.caption || null,
        thumbnail: apiData.thumbnailUrl || null,
        videoUrl: null,
        captionSegments: [],
        ocrHints: apiData.caption ? extractOcrHintsFromDescription(apiData.caption) : []
      };
    }
  }

  // If all methods failed
  if (!metadata) {
    return {
      success: false,
      error: {
        type: wasBlocked ? "content_unavailable" : "network_error",
        message: wasBlocked 
          ? "TikTok is blocking automated access. Try using a RapidAPI key for better results."
          : "Failed to extract TikTok content",
        retryable: !wasBlocked
      }
    };
  }

  const duration = Date.now() - startTime;
  const signalCount = metadata.captionSegments.length + metadata.ocrHints.length;

  const context: RawRecipeContext = {
    sourceUrl: parsed.normalizedUrl,
    platform: "tiktok" as const,
    title: metadata.title || `TikTok by @${parsed.creatorHandle || metadata.creator || "creator"}`,
    creator: parsed.creatorHandle || metadata.creator || "TikTok Creator",
    caption: metadata.description || undefined,
    transcript: metadata.description || undefined,
    transcriptSegments: metadata.captionSegments.length > 0 ? metadata.captionSegments : undefined,
    ocrText: metadata.ocrHints.length > 0 ? metadata.ocrHints : undefined,
    thumbnailUrl: metadata.thumbnail || undefined,
    thumbnailCandidates: metadata.thumbnail ? [metadata.thumbnail] : undefined,
    metadata: {
      videoId: parsed.videoId,
      creatorHandle: parsed.creatorHandle,
      extractionSource,
      wasBlocked
    }
  };

  return {
    success: true,
    context,
    metadata: {
      extractionSource,
      durationMs: duration,
      signalCount
    }
  };
};

export const tiktokAdapter: ExtractionAdapter = {
  name: "tiktok-native",
  platforms: ["tiktok"],
  priority: 90,
  extract: extractTikTokContext
};
