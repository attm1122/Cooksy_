import { appEnv } from "@/lib/env";
import { parseInstagramUrl } from "@/features/recipes/lib/platform";
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

// Extract Open Graph and JSON-LD metadata
const extractInstagramMetadata = (html: string) => {
  const patterns = {
    title: [/<meta[^>]*property="og:title"[^>]*content="([^"]+)"/i],
    description: [/<meta[^>]*property="og:description"[^>]*content="([^"]+)"/i],
    image: [/<meta[^>]*property="og:image"[^>]*content="([^"]+)"/i],
    video: [/<meta[^>]*property="og:video"[^>]*content="([^"]+)"/i],
    type: [/<meta[^>]*property="og:type"[^>]*content="([^"]+)"/i],
    // JSON-LD patterns
    jsonLd: /<script type="application\/ld\+json">([^<]+)<\/script>/gi
  };

  const extract = (patternList: RegExp[]): string | null => {
    for (const pattern of patternList) {
      const match = html.match(pattern);
      if (match?.[1]) return decodeHtmlEntities(match[1]);
    }
    return null;
  };

  // Extract JSON-LD data
  let jsonLdData: Record<string, unknown> | null = null;
  const jsonLdMatches = Array.from(html.matchAll(patterns.jsonLd));
  for (const match of jsonLdMatches) {
    try {
      const data = JSON.parse(match[1] || "") as Record<string, unknown>;
      // Look for VideoObject or ImageObject
      if (data["@type"] === "VideoObject" || data["@type"] === "ImageObject") {
        jsonLdData = data;
        break;
      }
    } catch {
      // Continue to next match
    }
  }

  const description = jsonLdData?.description as string || extract(patterns.description);
  
  // Parse caption for segments
  const captionSegments: TranscriptSegment[] = [];
  if (description) {
    // Instagram captions often have recipe steps
    const sentences = description
      .replace(/#[\w]+/g, "") // Remove hashtags
      .split(/[.!?]+/)
      .map(s => s.trim())
      .filter(s => s.length > 5 && s.length < 200);
    
    sentences.forEach((sentence, idx) => {
      captionSegments.push({
        id: `ig-caption-${idx}`,
        text: collapseWhitespace(sentence),
        startSeconds: idx * 3
      });
    });
  }

  // Extract hashtags as tags
  const hashtags = Array.from(description?.matchAll(/#([\w]+)/g) || []).map(m => m[1]);

  return {
    title: extract(patterns.title),
    description,
    thumbnail: extract(patterns.image),
    videoUrl: extract(patterns.video),
    isVideo: extract(patterns.type)?.includes("video") || Boolean(extract(patterns.video)),
    captionSegments,
    hashtags,
    author: jsonLdData?.author as { name?: string; identifier?: string } | undefined
  };
};

const scrapeInstagramPage = async (url: string) => {
  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Cache-Control": "no-cache"
      },
      signal: AbortSignal.timeout(12000)
    });

    if (!response.ok) {
      if (response.status === 401 || response.status === 403) {
        return { blocked: true, html: null, loginRequired: response.status === 401 };
      }
      return { blocked: false, html: null };
    }

    const html = await response.text();
    // Check if redirected to login page
    if (html.includes("login") && html.includes("instagram")) {
      return { blocked: true, html: null, loginRequired: true };
    }

    return { blocked: false, html, loginRequired: false };
  } catch (error) {
    const isTimeout = error instanceof Error && error.name === "TimeoutError";
    return { blocked: false, html: null, timeout: isTimeout };
  }
};

// Extract creator from Instagram URL pattern
const extractCreatorFromUrl = (url: string): string | null => {
  const match = url.match(/instagram\.com\/([^\/]+)/);
  return match?.[1] && !match[1].startsWith("p/") && !match[1].startsWith("reel/") 
    ? match[1] 
    : null;
};

// Parse recipe hints from Instagram caption
const parseRecipeHints = (caption: string): { ingredients: string[]; steps: string[] } => {
  const ingredients: string[] = [];
  const steps: string[] = [];
  
  const lines = caption.split(/\n/).map(l => l.trim()).filter(Boolean);
  
  let inIngredients = false;
  let inSteps = false;
  
  for (const line of lines) {
    const lower = line.toLowerCase();
    
    // Detect section headers
    if (/ingredients?:/i.test(lower)) {
      inIngredients = true;
      inSteps = false;
      continue;
    }
    if (/instructions?|directions?|steps?:|method:/i.test(lower)) {
      inIngredients = false;
      inSteps = true;
      continue;
    }
    
    // Skip hashtags and mentions at start
    if (line.startsWith("#") || line.startsWith("@")) continue;
    
    // Look for bullet points or numbered items
    if (/^[\-\*•]\s+/.test(line)) {
      const content = line.replace(/^[\-\*•]\s+/, "");
      if (inIngredients || /\d+\s*(?:cups?|tbsp|tsp|oz|g|kg|ml|lbs?)/i.test(content)) {
        ingredients.push(content);
      } else if (inSteps) {
        steps.push(content);
      }
    }
    
    // Look for numbered steps
    const stepMatch = line.match(/^(\d+)[.):\s]+(.+)$/);
    if (stepMatch) {
      steps.push(stepMatch[2]);
    }
  }
  
  return { ingredients, steps };
};

export const extractInstagramContext = async (sourceUrl: string): Promise<ExtractionResult> => {
  const startTime = Date.now();
  const parsed = parseInstagramUrl(sourceUrl);

  if (!parsed.mediaCode) {
    return {
      success: false,
      error: { type: "unsupported_url", message: "Could not extract Instagram media code" }
    };
  }

  let metadata: ReturnType<typeof extractInstagramMetadata> | null = null;
  let extractionSource = "instagram-og";
  let wasBlocked = false;
  let loginRequired = false;

  // Try scraping if enabled
  if (appEnv.enableInstagramScraping) {
    const scrapeResult = await scrapeInstagramPage(parsed.normalizedUrl);
    
    if (scrapeResult.blocked) {
      wasBlocked = true;
      loginRequired = scrapeResult.loginRequired || false;
    } else if (scrapeResult.html) {
      metadata = extractInstagramMetadata(scrapeResult.html);
    }
  }

  // If all methods failed
  if (!metadata) {
    return {
      success: false,
      error: {
        type: wasBlocked ? "content_unavailable" : "network_error",
        message: wasBlocked 
          ? loginRequired 
            ? "Instagram requires login to view this content."
            : "Instagram is blocking automated access. Consider using a scraping service API."
          : "Failed to extract Instagram content",
        retryable: !wasBlocked
      }
    };
  }

  // Parse recipe hints from caption
  const recipeHints = metadata.description ? parseRecipeHints(metadata.description) : { ingredients: [], steps: [] };

  const duration = Date.now() - startTime;
  const signalCount = metadata.captionSegments.length + recipeHints.ingredients.length + recipeHints.steps.length;

  const creator = metadata.author?.name || 
    extractCreatorFromUrl(sourceUrl) || 
    "Instagram Creator";

  const context: RawRecipeContext = {
    sourceUrl: parsed.normalizedUrl,
    platform: "instagram" as const,
    title: metadata.title || `${metadata.isVideo ? "Reel" : "Post"} by @${creator}`,
    creator,
    caption: metadata.description || undefined,
    transcript: metadata.description || undefined,
    transcriptSegments: metadata.captionSegments.length > 0 ? metadata.captionSegments : undefined,
    ocrText: recipeHints.ingredients.length > 0 ? [...recipeHints.ingredients, ...recipeHints.steps] : undefined,
    thumbnailUrl: metadata.thumbnail || undefined,
    thumbnailCandidates: metadata.thumbnail ? [metadata.thumbnail, metadata.videoUrl].filter(Boolean) as string[] : undefined,
    metadata: {
      mediaCode: parsed.mediaCode,
      isVideo: metadata.isVideo,
      hashtags: metadata.hashtags,
      extractionSource,
      wasBlocked,
      hasRecipeHints: recipeHints.ingredients.length > 0 || recipeHints.steps.length > 0
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

export const instagramAdapter: ExtractionAdapter = {
  name: "instagram-native",
  platforms: ["instagram"],
  priority: 80,
  extract: extractInstagramContext
};
