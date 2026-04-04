import { parseYouTubeUrl } from "@/features/recipes/lib/platform";
import type { RawRecipeContext, SourcePlatform, TranscriptSegment } from "@/features/recipes/types";
import type { ExtractionAdapter, ExtractionResult } from "./types";

const YOUTUBE_OEMBED_ENDPOINT = "https://www.youtube.com/oembed";
const YOUTUBE_WATCH_ENDPOINT = "https://www.youtube.com/watch";

const decodeHtmlEntities = (value: string) =>
  value
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");

const collapseWhitespace = (value: string) => value.replace(/\s+/g, " ").trim();

const extractJsonFromHtml = (html: string, markers: string[]): string | null => {
  for (const marker of markers) {
    const index = html.indexOf(marker);
    if (index === -1) continue;

    const start = html.indexOf("{", index);
    if (start === -1) continue;

    let depth = 0;
    let inString = false;
    let escaping = false;

    for (let cursor = start; cursor < html.length; cursor++) {
      const char = html[cursor];
      if (escaping) {
        escaping = false;
        continue;
      }
      if (char === "\\") {
        escaping = true;
        continue;
      }
      if (char === '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;

      if (char === "{") depth++;
      else if (char === "}") {
        depth--;
        if (depth === 0) return html.slice(start, cursor + 1);
      }
    }
  }
  return null;
};

type CaptionTrack = {
  baseUrl: string;
  languageCode?: string;
  name?: { simpleText?: string };
};

const extractCaptionTracks = (html: string): CaptionTrack[] => {
  const jsonCandidate = extractJsonFromHtml(html, ['"captions":', "ytInitialPlayerResponse"]);
  if (!jsonCandidate) return [];

  try {
    const parsed = JSON.parse(jsonCandidate) as {
      captions?: { playerCaptionsTracklistRenderer?: { captionTracks?: CaptionTrack[] } };
      playerCaptionsTracklistRenderer?: { captionTracks?: CaptionTrack[] };
    };
    return (
      parsed.captions?.playerCaptionsTracklistRenderer?.captionTracks ??
      parsed.playerCaptionsTracklistRenderer?.captionTracks ??
      []
    );
  } catch {
    return [];
  }
};

const extractVideoMetadata = (html: string) => {
  const patterns = {
    title: [/<meta name="title" content="([^"]+)">/, /"title":"([^"]+)"/],
    creator: [/<link rel="canonical" href="[^"]*\/channel\/([^"]+)"/, /"ownerChannelName":"([^"]+)"/, /"author":"([^"]+)"/],
    description: [/"shortDescription":"([^"]+)"/, /"description":{"simpleText":"([^"]+)"}/]
  };

  const extract = (patternList: RegExp[]): string | null => {
    for (const pattern of patternList) {
      const match = html.match(pattern);
      if (match?.[1]) return collapseWhitespace(decodeHtmlEntities(match[1].replace(/\\n/g, " ")));
    }
    return null;
  };

  return {
    title: extract(patterns.title),
    creator: extract(patterns.creator),
    description: extract(patterns.description)
  };
};

const parseTranscriptXml = (xml: string): { text: string; segments: TranscriptSegment[] } => {
  const matches = Array.from(xml.matchAll(/<text\b[^>]*start="([^"]+)"(?:\s+dur="([^"]+)")?[^>]*>([\s\S]*?)<\/text>/g));
  
  const segments: TranscriptSegment[] = matches.map((match, index) => {
    const startSeconds = parseFloat(match[1]);
    const durationSeconds = match[2] ? parseFloat(match[2]) : undefined;
    const text = decodeHtmlEntities(match[3].replace(/<[^>]+>/g, " "));
    
    return {
      id: `yt-seg-${index}`,
      text: collapseWhitespace(text),
      startSeconds,
      durationSeconds
    };
  });

  const fullText = segments.map(s => s.text).join(" ");
  return { text: fullText, segments };
};

const fetchTranscript = async (track: CaptionTrack): Promise<{ text: string; segments: TranscriptSegment[] } | null> => {
  try {
    const response = await fetch(track.baseUrl, { 
      headers: { "Accept": "application/xml" },
      signal: AbortSignal.timeout(10000)
    });
    if (!response.ok) return null;
    return parseTranscriptXml(await response.text());
  } catch {
    return null;
  }
};

const fetchOEmbed = async (videoId: string) => {
  try {
    const url = new URL(YOUTUBE_OEMBED_ENDPOINT);
    url.searchParams.set("url", `https://www.youtube.com/watch?v=${videoId}`);
    url.searchParams.set("format", "json");

    const response = await fetch(url.toString(), {
      signal: AbortSignal.timeout(8000)
    });
    
    if (!response.ok) return null;
    return response.json() as Promise<{
      title?: string;
      author_name?: string;
      thumbnail_url?: string;
    }>;
  } catch {
    return null;
  }
};

const fetchWatchPage = async (videoId: string) => {
  try {
    const response = await fetch(`${YOUTUBE_WATCH_ENDPOINT}?v=${videoId}`, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      },
      signal: AbortSignal.timeout(15000)
    });

    if (!response.ok) return null;
    return response.text();
  } catch {
    return null;
  }
};

export const extractYouTubeContext = async (sourceUrl: string): Promise<ExtractionResult> => {
  const startTime = Date.now();
  const parsed = parseYouTubeUrl(sourceUrl);

  if (!parsed.videoId) {
    return {
      success: false,
      error: { type: "unsupported_url", message: "Could not extract YouTube video ID" }
    };
  }

  try {
    // Fetch oEmbed and watch page in parallel
    const [oembed, watchHtml] = await Promise.all([
      fetchOEmbed(parsed.videoId),
      fetchWatchPage(parsed.videoId)
    ]);

    if (!oembed && !watchHtml) {
      return {
        success: false,
        error: { type: "network_error", message: "Failed to fetch YouTube data", retryable: true }
      };
    }

    // Extract metadata
    const metadata = watchHtml ? extractVideoMetadata(watchHtml) : { title: null, creator: null, description: null };
    const title = oembed?.title || metadata.title || "YouTube Recipe";
    const creator = oembed?.author_name || metadata.creator || "YouTube Creator";

    // Extract transcript
    let transcript: string | undefined;
    let transcriptSegments: TranscriptSegment[] | undefined;

    if (watchHtml) {
      const captionTracks = extractCaptionTracks(watchHtml);
      const preferredTrack = captionTracks.find(t => t.languageCode?.startsWith("en")) || captionTracks[0];
      
      if (preferredTrack) {
        const transcriptData = await fetchTranscript(preferredTrack);
        if (transcriptData) {
          transcript = transcriptData.text;
          transcriptSegments = transcriptData.segments;
        }
      }
    }

    // Build thumbnail candidates
    const thumbnailCandidates = [
      oembed?.thumbnail_url,
      `https://img.youtube.com/vi/${parsed.videoId}/maxresdefault.jpg`,
      `https://img.youtube.com/vi/${parsed.videoId}/hqdefault.jpg`,
      `https://img.youtube.com/vi/${parsed.videoId}/mqdefault.jpg`
    ].filter(Boolean) as string[];

    const duration = Date.now() - startTime;
    const signalCount = (transcriptSegments?.length || 0) + (metadata.description ? 1 : 0);

    const context: RawRecipeContext = {
      sourceUrl: parsed.normalizedUrl,
      platform: "youtube" as const,
      title,
      creator,
      caption: metadata.description || undefined,
      transcript,
      transcriptSegments,
      thumbnailUrl: thumbnailCandidates[0],
      thumbnailCandidates,
      metadata: {
        videoId: parsed.videoId,
        extractionSource: transcript ? "youtube-oembed+transcript" : "youtube-oembed",
        hasCaptions: !!transcript,
        captionTrackCount: transcriptSegments?.length || 0
      }
    };

    return {
      success: true,
      context,
      metadata: {
        extractionSource: transcript ? "youtube-oembed+transcript" : "youtube-oembed",
        durationMs: duration,
        signalCount
      }
    };
  } catch (error) {
    const isTimeout = error instanceof Error && error.name === "TimeoutError";
    return {
      success: false,
      error: {
        type: isTimeout ? "timeout" : "unknown",
        message: isTimeout ? "YouTube extraction timed out" : "Failed to extract YouTube content"
      }
    };
  }
};

export const youtubeAdapter: ExtractionAdapter = {
  name: "youtube-native",
  platforms: ["youtube"],
  priority: 100,
  extract: extractYouTubeContext
};
