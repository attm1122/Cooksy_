import { parseYouTubeUrl } from "@/features/recipes/lib/platform";

export type YouTubeOEmbedMetadata = {
  title: string;
  author_name: string;
  author_url?: string;
  thumbnail_url?: string;
  width?: number;
  height?: number;
};

export const buildYouTubeOEmbedUrl = (sourceUrl: string) =>
  `https://www.youtube.com/oembed?url=${encodeURIComponent(sourceUrl)}&format=json`;

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
