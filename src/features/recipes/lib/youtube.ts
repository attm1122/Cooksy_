import { parseYouTubeUrl } from "@/features/recipes/lib/platform";

export type YouTubeOEmbedMetadata = {
  title: string;
  author_name: string;
  author_url?: string;
  thumbnail_url?: string;
  width?: number;
  height?: number;
};

export type YouTubeCaptionTrack = {
  baseUrl: string;
  languageCode?: string;
  name?: {
    simpleText?: string;
  };
};

export type YouTubeWatchPageSignals = {
  title?: string | null;
  creator?: string | null;
  description?: string | null;
  transcript?: string | null;
  captionTracks?: YouTubeCaptionTrack[];
};

export const buildYouTubeOEmbedUrl = (sourceUrl: string) =>
  `https://www.youtube.com/oembed?url=${encodeURIComponent(sourceUrl)}&format=json`;

export const buildYouTubeWatchUrl = (sourceUrl: string) => {
  const parsed = parseYouTubeUrl(sourceUrl);

  if (!parsed.videoId) {
    return parsed.normalizedUrl;
  }

  return `https://www.youtube.com/watch?v=${parsed.videoId}`;
};

export const getYouTubeThumbnailFromVideoId = (sourceUrl: string) => {
  const parsed = parseYouTubeUrl(sourceUrl);

  if (!parsed.videoId) {
    return null;
  }

  return parsed.videoId.length === 11
    ? `https://img.youtube.com/vi/${parsed.videoId}/hqdefault.jpg`
    : `https://picsum.photos/seed/youtube-${parsed.videoId}/1280/720`;
};

export const fetchYouTubeOEmbedMetadata = async (sourceUrl: string): Promise<YouTubeOEmbedMetadata | null> => {
  const response = await fetch(buildYouTubeOEmbedUrl(sourceUrl));

  if (!response.ok) {
    return null;
  }

  return (await response.json()) as YouTubeOEmbedMetadata;
};

const decodeHtmlEntities = (value: string) =>
  value
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");

const collapseWhitespace = (value: string) => value.replace(/\s+/g, " ").trim();

const pickJsonCandidate = (html: string, markers: string[]) => {
  for (const marker of markers) {
    const index = html.indexOf(marker);

    if (index === -1) {
      continue;
    }

    const start = html.indexOf("{", index);
    if (start === -1) {
      continue;
    }

    let depth = 0;
    let inString = false;
    let escaping = false;

    for (let cursor = start; cursor < html.length; cursor += 1) {
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

      if (inString) {
        continue;
      }

      if (char === "{") {
        depth += 1;
      } else if (char === "}") {
        depth -= 1;

        if (depth === 0) {
          return html.slice(start, cursor + 1);
        }
      }
    }
  }

  return null;
};

export const extractCaptionTracksFromWatchHtml = (html: string): YouTubeCaptionTrack[] => {
  const jsonCandidate = pickJsonCandidate(html, ['"captions":', "ytInitialPlayerResponse ="]);

  if (!jsonCandidate) {
    return [];
  }

  try {
    const parsed = JSON.parse(jsonCandidate) as {
      captions?: {
        playerCaptionsTracklistRenderer?: {
          captionTracks?: YouTubeCaptionTrack[];
        };
      };
      playerCaptionsTracklistRenderer?: {
        captionTracks?: YouTubeCaptionTrack[];
      };
    };

    return parsed.captions?.playerCaptionsTracklistRenderer?.captionTracks ?? parsed.playerCaptionsTracklistRenderer?.captionTracks ?? [];
  } catch {
    return [];
  }
};

export const extractDescriptionFromWatchHtml = (html: string) => {
  const patterns = [
    /"shortDescription":"([^"]+)"/,
    /"description":{"simpleText":"([^"]+)"}/
  ];

  for (const pattern of patterns) {
    const match = html.match(pattern);

    if (match?.[1]) {
      return collapseWhitespace(decodeHtmlEntities(match[1].replace(/\\n/g, " ")));
    }
  }

  return null;
};

export const extractCreatorFromWatchHtml = (html: string) => {
  const patterns = [
    /"ownerChannelName":"([^"]+)"/,
    /"author":"([^"]+)"/
  ];

  for (const pattern of patterns) {
    const match = html.match(pattern);

    if (match?.[1]) {
      return collapseWhitespace(decodeHtmlEntities(match[1]));
    }
  }

  return null;
};

export const extractTitleFromWatchHtml = (html: string) => {
  const patterns = [
    /<meta name="title" content="([^"]+)">/,
    /"title":"([^"]+)"/
  ];

  for (const pattern of patterns) {
    const match = html.match(pattern);

    if (match?.[1]) {
      return collapseWhitespace(decodeHtmlEntities(match[1]));
    }
  }

  return null;
};

export const parseYouTubeTranscriptXml = (xml: string) => {
  const matches = Array.from(xml.matchAll(/<text\b[^>]*>([\s\S]*?)<\/text>/g));

  if (!matches.length) {
    return null;
  }

  return collapseWhitespace(
    decodeHtmlEntities(
      matches
        .map((match) => match[1].replace(/<[^>]+>/g, " "))
        .join(" ")
    )
  );
};

export const fetchYouTubeTranscriptFromTrack = async (track: YouTubeCaptionTrack) => {
  const response = await fetch(track.baseUrl);

  if (!response.ok) {
    return null;
  }

  return parseYouTubeTranscriptXml(await response.text());
};

export const fetchYouTubeWatchPageSignals = async (sourceUrl: string): Promise<YouTubeWatchPageSignals> => {
  const response = await fetch(buildYouTubeWatchUrl(sourceUrl));

  if (!response.ok) {
    return {};
  }

  const html = await response.text();
  const captionTracks = extractCaptionTracksFromWatchHtml(html);
  const preferredTrack =
    captionTracks.find((track) => track.languageCode?.toLowerCase().startsWith("en")) ?? captionTracks[0];
  const transcript = preferredTrack ? await fetchYouTubeTranscriptFromTrack(preferredTrack) : null;

  return {
    title: extractTitleFromWatchHtml(html),
    creator: extractCreatorFromWatchHtml(html),
    description: extractDescriptionFromWatchHtml(html),
    transcript,
    captionTracks
  };
};
