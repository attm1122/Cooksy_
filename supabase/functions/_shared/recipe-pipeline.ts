export type SourcePlatform = "youtube" | "tiktok" | "instagram";
export type ThumbnailSource = SourcePlatform | "generated";
export type SourceSignalOrigin = "oembed" | "watch-page" | "open-graph" | "json-ld" | "mock-fallback";
export type EvidenceSignalType = "transcript" | "caption" | "ocr" | "comment" | "metadata";

export type EvidenceSignal = {
  id: string;
  type: EvidenceSignalType;
  content: string;
  weight: number;
  source: string;
  timestamp?: number;
};

export type RankedTextCandidate = {
  value: string;
  weight: number;
  source: string;
};

export type TranscriptSegment = {
  id: string;
  text: string;
  startSeconds?: number;
  durationSeconds?: number;
  sourceSignalId?: string;
};

export type OcrBlock = {
  id: string;
  text: string;
  context?: string | null;
  timestampSeconds?: number;
  boundingBox?: {
    x: number;
    y: number;
    width: number;
    height: number;
  } | null;
  sourceSignalId?: string;
};

export type IngredientSignal = {
  id: string;
  name: string;
  quantity?: string | null;
  unit?: string | null;
  note?: string | null;
  weight: number;
  source: string;
  sourceSignalIds: string[];
  timestamp?: number;
};

export type StepSignal = {
  id: string;
  instruction: string;
  action?: string | null;
  object?: string | null;
  weight: number;
  source: string;
  sourceSignalIds: string[];
  timestamp?: number;
};

export type Ingredient = {
  id: string;
  name: string;
  quantity?: string | null;
  unit?: string | null;
  note?: string | null;
  optional?: boolean;
  inferred?: boolean;
};

export type RecipeStep = {
  id: string;
  order: number;
  instruction: string;
  durationMinutes?: number | null;
  temperature?: string | null;
  inferred?: boolean;
};

export type RawRecipeContext = {
  sourceUrl: string;
  platform: SourcePlatform;
  title?: string | null;
  creator?: string | null;
  caption?: string | null;
  transcript?: string | null;
  ocrText?: string[] | null;
  comments?: string[] | null;
  metadata?: Record<string, unknown> | null;
  thumbnailUrl?: string | null;
  signals?: EvidenceSignal[];
  transcriptSegments?: TranscriptSegment[];
  ocrBlocks?: OcrBlock[];
  ingredientSignals?: IngredientSignal[];
  stepSignals?: StepSignal[];
  thumbnailCandidates?: string[];
  creators?: string[];
  titles?: string[];
  titleCandidates?: RankedTextCandidate[];
};

export type SourceSignals = {
  title?: string | null;
  description?: string | null;
  creator?: string | null;
  thumbnailUrl?: string | null;
  transcript?: string | null;
  signalOrigins: SourceSignalOrigin[];
};

export type SourceEvidence = {
  combinedText: string;
  transcriptText: string;
  captionText: string;
  ocrText: string;
  commentsText: string;
  explicitQuantityMentions: number;
  cueMentions: string[];
  hasStrongTranscript: boolean;
  hasAnyTextSignals: boolean;
  signalOriginCount: number;
  lowQualitySignalCount: number;
  actionVerbCount: number;
  titles: string[];
  creators: string[];
  thumbnailCandidates: string[];
};

export type CandidateIngredient = {
  id: string;
  name: string;
  quantity?: string | null;
  unit?: string | null;
  note?: string | null;
  confidence: number;
  uncertain?: boolean;
  supportingSignals: string[];
};

export type CandidateStep = {
  id: string;
  instruction: string;
  orderHint?: number | null;
  actionVerb?: string | null;
  object?: string | null;
  durationMinutes?: number | null;
  timestamp?: number | null;
  confidence: number;
  uncertain?: boolean;
  supportingSignals: string[];
};

export type CandidateMetadata = {
  titleCandidates: RankedTextCandidate[];
  creatorCandidates: RankedTextCandidate[];
  servings?: {
    value: number | null;
    confidence: number;
    supportingSignals: string[];
  };
  prepTimeMinutes?: {
    value: number | null;
    confidence: number;
    supportingSignals: string[];
  };
  cookTimeMinutes?: {
    value: number | null;
    confidence: number;
    supportingSignals: string[];
  };
  totalTimeMinutes?: {
    value: number | null;
    confidence: number;
    supportingSignals: string[];
  };
};

export type AggregatedEvidence = {
  ingredients: CandidateIngredient[];
  steps: CandidateStep[];
  metadata: CandidateMetadata;
  normalizedSignals: EvidenceSignal[];
};

export type ConfidenceReport = {
  score: number;
  warnings: string[];
  missingFields: string[];
  lowConfidenceAreas: string[];
};

export type ReconstructionResult = {
  title: string;
  description?: string | null;
  servings?: number | null;
  prepTimeMinutes?: number | null;
  cookTimeMinutes?: number | null;
  totalTimeMinutes?: number | null;
  ingredients: Ingredient[];
  steps: RecipeStep[];
  thumbnailUrl?: string | null;
  thumbnailSource: ThumbnailSource;
  thumbnailFallbackStyle?: string | null;
  sourceCreator?: string | null;
  sourceTitle?: string | null;
  confidenceScore: number;
  confidenceReport: ConfidenceReport;
  inferredFields: string[];
  missingFields: string[];
  validationWarnings: string[];
  rawExtraction: RawRecipeContext;
};

type PersistedRecipe = {
  status: "ready";
  importJobId: string;
  title: string;
  description: string;
  heroNote: string;
  imageLabel: string;
  thumbnailUrl: string | null;
  thumbnailSource: ThumbnailSource;
  thumbnailFallbackStyle?: string | null;
  servings: number;
  prepTimeMinutes: number;
  cookTimeMinutes: number;
  totalTimeMinutes: number;
  confidence: "high" | "medium" | "low";
  confidenceScore: number;
  confidenceNote: string;
  inferredFields: string[];
  missingFields: string[];
  validationWarnings: string[];
  rawExtraction: RawRecipeContext;
  isSaved: true;
  source: {
    creator: string;
    url: string;
    platform: SourcePlatform;
  };
  ingredients: Array<{
    id: string;
    name: string;
    quantity: string;
    optional?: boolean;
  }>;
  steps: Array<{
    id: string;
    title: string;
    instruction: string;
    durationMinutes?: number | null;
  }>;
  tags: string[];
};

type MetadataHints = {
  ingredientHints?: Record<string, unknown>[];
  stepHints?: Record<string, unknown>[];
  servingsHint?: number;
  prepTimeMinutesHint?: number;
  cookTimeMinutesHint?: number;
};

const FOOD_CUES = [
  "chicken",
  "garlic",
  "cream",
  "parmesan",
  "spinach",
  "salmon",
  "honey",
  "rice",
  "pasta",
  "orzo",
  "stock",
  "butter",
  "tomato",
  "cucumber",
  "avocado",
  "lemon"
] as const;

const ACTION_VERBS = [
  "add",
  "bake",
  "boil",
  "coat",
  "cook",
  "finish",
  "fold",
  "glaze",
  "mix",
  "pour",
  "roast",
  "season",
  "sear",
  "serve",
  "simmer",
  "stir",
  "toast",
  "whisk"
] as const;

const UNIT_ALIASES: Record<string, string> = {
  tablespoon: "tbsp",
  tablespoons: "tbsp",
  tbsp: "tbsp",
  teaspoon: "tsp",
  teaspoons: "tsp",
  tsp: "tsp",
  cup: "cup",
  cups: "cup",
  ounce: "oz",
  ounces: "oz",
  oz: "oz",
  pound: "lb",
  pounds: "lb",
  lbs: "lb",
  lb: "lb",
  clove: "cloves",
  cloves: "cloves",
  fillet: "fillets",
  fillets: "fillets",
  piece: "pieces",
  pieces: "pieces",
  handful: "handfuls",
  handfuls: "handfuls"
};

const QUANTITY_PATTERN =
  /\b(\d+\s?\/\s?\d+|\d+\.\d+|\d+|half|quarter)\s*(cup|cups|tbsp|tablespoon|tablespoons|tsp|teaspoon|teaspoons|oz|ounce|ounces|lb|lbs|pound|pounds|clove|cloves|fillet|fillets|piece|pieces|handful|handfuls)?\s*([a-z][a-z\s-]{2,})/i;
const TITLE_SPLIT_PATTERN = /[.!?]\s+/;

const readHints = (context: RawRecipeContext): MetadataHints => ((context.metadata ?? {}) as MetadataHints);
const normalizeText = (value: string | null | undefined) => value?.replace(/\s+/g, " ").trim() ?? "";
const canonicalize = (value: string) => normalizeText(value).toLowerCase();
const collapseWhitespace = (value: string) => value.replace(/\s+/g, " ").trim();
const buildId = (prefix: string, index: number) => `${prefix}-${index + 1}`;

const normalizeUnit = (value: string | null | undefined) => {
  if (!value) {
    return null;
  }

  return UNIT_ALIASES[canonicalize(value)] ?? canonicalize(value);
};

const toSentenceParts = (value: string) =>
  normalizeText(value)
    .split(TITLE_SPLIT_PATTERN)
    .map((item) => item.trim())
    .filter(Boolean);

const dedupeRankedCandidates = (candidates: RankedTextCandidate[]) => {
  const map = new Map<string, RankedTextCandidate>();
  candidates.forEach((candidate) => {
    const key = canonicalize(candidate.value);
    const existing = map.get(key);
    if (!existing || candidate.weight > existing.weight) {
      map.set(key, candidate);
    }
  });
  return Array.from(map.values()).sort((left, right) => right.weight - left.weight);
};

const toRankedCandidate = (value: string, weight: number, source: string): RankedTextCandidate => ({
  value: normalizeText(value),
  weight,
  source
});

const inferActionVerb = (content: string) => ACTION_VERBS.find((verb) => canonicalize(content).includes(verb)) ?? null;

const normalizeHost = (value: string) => value.toLowerCase().replace(/^www\./, "");
const slugFromTitle = (value: string) => value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

const getYouTubeVideoId = (value: string) => {
  try {
    const url = new URL(value);
    const host = normalizeHost(url.hostname);
    const path = url.pathname;
    if (host === "youtu.be") {
      return path.split("/").filter(Boolean)[0] ?? null;
    }
    if (!["youtube.com", "m.youtube.com"].includes(host)) {
      return null;
    }
    if (path === "/watch") {
      return url.searchParams.get("v");
    }
    if (path.startsWith("/shorts/") || path.startsWith("/live/") || path.startsWith("/embed/")) {
      return path.split("/").filter(Boolean)[1] ?? null;
    }
  } catch {
    return null;
  }
  return null;
};

const getYouTubeThumbnailFromVideoId = (sourceUrl: string) => {
  const videoId = getYouTubeVideoId(sourceUrl);
  return videoId ? `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg` : null;
};

type YouTubeCaptionTrack = {
  baseUrl: string;
  languageCode?: string;
  name?: {
    simpleText?: string;
  };
};

const fetchYouTubeOEmbedMetadata = async (sourceUrl: string) => {
  const endpoint = new URL("https://www.youtube.com/oembed");
  endpoint.searchParams.set("url", sourceUrl);
  endpoint.searchParams.set("format", "json");
  const response = await fetch(endpoint.toString());
  if (!response.ok) {
    throw new Error(`YouTube oEmbed failed with ${response.status}`);
  }
  return (await response.json()) as {
    title?: string;
    author_name?: string;
    author_url?: string;
    thumbnail_url?: string;
  };
};

const decodeHtmlEntities = (value: string) =>
  value
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");

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

const extractCaptionTracksFromWatchHtml = (html: string): YouTubeCaptionTrack[] => {
  const jsonCandidate = pickJsonCandidate(html, ['"captions":', "ytInitialPlayerResponse ="]);
  if (!jsonCandidate) {
    return [];
  }
  try {
    const parsed = JSON.parse(jsonCandidate) as {
      captions?: { playerCaptionsTracklistRenderer?: { captionTracks?: YouTubeCaptionTrack[] } };
      playerCaptionsTracklistRenderer?: { captionTracks?: YouTubeCaptionTrack[] };
    };
    return parsed.captions?.playerCaptionsTracklistRenderer?.captionTracks ?? parsed.playerCaptionsTracklistRenderer?.captionTracks ?? [];
  } catch {
    return [];
  }
};

const extractDescriptionFromWatchHtml = (html: string) => {
  const patterns = [/"shortDescription":"([^"]+)"/, /"description":{"simpleText":"([^"]+)"}/];
  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match?.[1]) {
      return collapseWhitespace(decodeHtmlEntities(match[1].replace(/\\n/g, " ")));
    }
  }
  return null;
};

const extractCreatorFromWatchHtml = (html: string) => {
  const patterns = [/"ownerChannelName":"([^"]+)"/, /"author":"([^"]+)"/];
  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match?.[1]) {
      return collapseWhitespace(decodeHtmlEntities(match[1]));
    }
  }
  return null;
};

const extractTitleFromWatchHtml = (html: string) => {
  const patterns = [/<meta name="title" content="([^"]+)">/, /"title":"([^"]+)"/];
  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match?.[1]) {
      return collapseWhitespace(decodeHtmlEntities(match[1]));
    }
  }
  return null;
};

const parseYouTubeTranscriptXml = (xml: string) => {
  const matches = Array.from(xml.matchAll(/<text\b([^>]*)>([\s\S]*?)<\/text>/g));
  if (!matches.length) {
    return { transcript: null as string | null, segments: [] as TranscriptSegment[] };
  }

  const segments = matches.map((match, index) => {
    const attrs = match[1] ?? "";
    const text = decodeHtmlEntities(match[2].replace(/<[^>]+>/g, " "));
    const startMatch = attrs.match(/\bstart="([^"]+)"/);
    const durMatch = attrs.match(/\bdur="([^"]+)"/);
    return {
      id: `transcript-${index + 1}`,
      text: collapseWhitespace(text),
      startSeconds: startMatch?.[1] ? Number(startMatch[1]) : undefined,
      durationSeconds: durMatch?.[1] ? Number(durMatch[1]) : undefined
    };
  });

  return {
    transcript: collapseWhitespace(segments.map((segment) => segment.text).join(" ")),
    segments
  };
};

const fetchYouTubeTranscriptFromTrack = async (track: YouTubeCaptionTrack) => {
  const response = await fetch(track.baseUrl);
  if (!response.ok) {
    return { transcript: null as string | null, segments: [] as TranscriptSegment[] };
  }
  return parseYouTubeTranscriptXml(await response.text());
};

const fetchYouTubeWatchPageSignals = async (sourceUrl: string) => {
  const response = await fetch(`https://www.youtube.com/watch?v=${getYouTubeVideoId(sourceUrl) ?? ""}`);
  if (!response.ok) {
    return {};
  }

  const html = await response.text();
  const captionTracks = extractCaptionTracksFromWatchHtml(html);
  const preferredTrack = captionTracks.find((track) => track.languageCode?.toLowerCase().startsWith("en")) ?? captionTracks[0];
  const transcriptPayload = preferredTrack ? await fetchYouTubeTranscriptFromTrack(preferredTrack) : { transcript: null, segments: [] };

  return {
    title: extractTitleFromWatchHtml(html),
    creator: extractCreatorFromWatchHtml(html),
    description: extractDescriptionFromWatchHtml(html),
    transcript: transcriptPayload.transcript,
    transcriptSegments: transcriptPayload.segments,
    captionTracks
  };
};

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

const fetchSocialPageSignals = async ({
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
    return { signalOrigins: ["mock-fallback"] };
  }
  const html = await response.text();
  const title = extractMetaContent(html, "property", "og:title") ?? extractMetaContent(html, "name", "twitter:title");
  const description =
    extractMetaContent(html, "property", "og:description") ?? extractMetaContent(html, "name", "twitter:description");
  const thumbnailUrl =
    extractMetaContent(html, "property", "og:image") ?? extractMetaContent(html, "name", "twitter:image");
  const jsonLdCreator = extractCreatorFromJsonLd(html);
  const creator = extractMetaContent(html, "name", "author") ?? jsonLdCreator ?? deriveCreatorFallback(html, platform, creatorHint);
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

const inferDimensionsFromUrl = (url: string) => {
  if (/maxresdefault/.test(url)) {
    return { width: 1280, height: 720 };
  }
  if (/hqdefault/.test(url)) {
    return { width: 480, height: 360 };
  }
  const match = url.match(/\/(\d{3,4})\/(\d{3,4})(?:$|[/?#])/);
  return match ? { width: Number(match[1]), height: Number(match[2]) } : null;
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

const selectBestThumbnailCandidate = (candidates: string[], platform?: SourcePlatform) => {
  const unique = Array.from(new Set(candidates.filter(Boolean)));
  if (!unique.length) {
    return null;
  }
  return unique.sort((left, right) => scoreThumbnailCandidate(right, platform) - scoreThumbnailCandidate(left, platform))[0] ?? null;
};

const buildTikTokThumbnailUrl = (sourceUrl: string) => `https://picsum.photos/seed/tiktok-${slugFromTitle(sourceUrl)}/1280/960`;
const buildInstagramThumbnailUrl = (sourceUrl: string) => `https://picsum.photos/seed/instagram-${slugFromTitle(sourceUrl)}/1280/960`;

const sanitizeIngredientName = (name: string) =>
  normalizeText(name)
    .replace(/\b(filets|fillets)\b/gi, "")
    .replace(/\s+/g, " ")
    .trim();

const extractIngredientFromText = (
  content: string,
  sourceSignalId: string,
  weight: number,
  source: string,
  timestamp?: number
): IngredientSignal | null => {
  const normalized = normalizeText(content);
  const match = normalized.match(QUANTITY_PATTERN);
  if (!match) {
    const cue = FOOD_CUES.find((item) => canonicalize(normalized).includes(item));
    if (!cue) {
      return null;
    }
    return {
      id: `${sourceSignalId}-ingredient`,
      name: cue.charAt(0).toUpperCase() + cue.slice(1),
      quantity: null,
      unit: null,
      note: null,
      weight,
      source,
      sourceSignalIds: [sourceSignalId],
      timestamp
    };
  }

  const quantity = match[1] ? match[1].replace(/^half$/i, "1/2").replace(/^quarter$/i, "1/4") : null;
  const unit = normalizeUnit(match[2]);
  const rawName = match[3] ? match[3].replace(/\b(with|and|for|until)\b.*$/i, "") : "";
  const name = sanitizeIngredientName(normalizeText(rawName).replace(/\b(of|the|a)\b/gi, "").replace(/\s+/g, " ").trim());
  if (!name) {
    return null;
  }
  return {
    id: `${sourceSignalId}-ingredient`,
    name: name.replace(/\b\w/g, (char) => char.toUpperCase()),
    quantity,
    unit,
    note: null,
    weight,
    source,
    sourceSignalIds: [sourceSignalId],
    timestamp
  };
};

const extractStepFromText = (
  content: string,
  sourceSignalId: string,
  weight: number,
  source: string,
  timestamp?: number
): StepSignal | null => {
  const normalized = normalizeText(content);
  const action = inferActionVerb(normalized);
  if (!action) {
    return null;
  }
  const objectCue = FOOD_CUES.find((cue) => canonicalize(normalized).includes(cue)) ?? null;
  return {
    id: `${sourceSignalId}-step`,
    instruction: normalized,
    action,
    object: objectCue ? objectCue.charAt(0).toUpperCase() + objectCue.slice(1) : null,
    weight,
    source,
    sourceSignalIds: [sourceSignalId],
    timestamp
  };
};

const deriveTranscriptSegments = (context: RawRecipeContext): TranscriptSegment[] => {
  if (context.transcriptSegments?.length) {
    return context.transcriptSegments;
  }
  return toSentenceParts(context.transcript ?? "").map((text, index) => ({
    id: buildId("segment", index),
    text,
    startSeconds: index * 8,
    durationSeconds: 8
  }));
};

const deriveOcrBlocks = (context: RawRecipeContext): OcrBlock[] => {
  if (context.ocrBlocks?.length) {
    return context.ocrBlocks;
  }
  return (context.ocrText ?? []).map((text, index) => ({
    id: buildId("ocr", index),
    text,
    context: "on-screen text"
  }));
};

const deriveSignals = (context: RawRecipeContext): EvidenceSignal[] => {
  const derivedSignals: EvidenceSignal[] = [];
  if (context.signals?.length) {
    derivedSignals.push(...context.signals);
  }
  if (context.caption) {
    derivedSignals.push({
      id: "caption-1",
      type: "caption",
      content: context.caption,
      weight: 0.72,
      source: "post-caption"
    });
  }
  deriveTranscriptSegments(context).forEach((segment, index) => {
    derivedSignals.push({
      id: segment.sourceSignalId ?? `transcript-${index + 1}`,
      type: "transcript",
      content: segment.text,
      weight: 0.9,
      source: "transcript",
      timestamp: segment.startSeconds
    });
  });
  deriveOcrBlocks(context).forEach((block, index) => {
    derivedSignals.push({
      id: block.sourceSignalId ?? `ocr-${index + 1}`,
      type: "ocr",
      content: block.text,
      weight: 0.45,
      source: block.context ?? "ocr",
      timestamp: block.timestampSeconds
    });
  });
  (context.comments ?? []).forEach((comment, index) => {
    derivedSignals.push({
      id: `comment-${index + 1}`,
      type: "comment",
      content: comment,
      weight: 0.25,
      source: "comments"
    });
  });
  [context.title ? toRankedCandidate(context.title, 0.8, "title") : null, context.creator ? toRankedCandidate(context.creator, 0.7, "creator") : null]
    .filter(Boolean)
    .forEach((candidate, index) => {
      derivedSignals.push({
        id: `metadata-${index + 1}`,
        type: "metadata",
        content: candidate!.value,
        weight: candidate!.weight,
        source: candidate!.source
      });
    });

  const deduped = new Map<string, EvidenceSignal>();
  derivedSignals.forEach((signal) => {
    const key = `${signal.type}:${canonicalize(signal.content)}`;
    const existing = deduped.get(key);
    if (!existing || signal.weight > existing.weight) {
      deduped.set(key, signal);
    }
  });
  return Array.from(deduped.values());
};

export const hydrateEvidenceContext = (context: RawRecipeContext): RawRecipeContext => {
  const titles = Array.from(
    new Set(
      [context.title, ...(context.titles ?? []), ...(context.titleCandidates ?? []).map((candidate) => candidate.value)]
        .map((value) => normalizeText(value))
        .filter(Boolean)
    )
  );
  const creators = Array.from(new Set([context.creator, ...(context.creators ?? [])].map((value) => normalizeText(value)).filter(Boolean)));
  const thumbnailCandidates = Array.from(
    new Set(
      [
        context.thumbnailUrl,
        ...(context.thumbnailCandidates ?? []),
        context.platform === "youtube"
          ? getYouTubeThumbnailFromVideoId(context.sourceUrl)
          : context.platform === "tiktok"
            ? buildTikTokThumbnailUrl(context.sourceUrl)
            : buildInstagramThumbnailUrl(context.sourceUrl)
      ]
        .map((value) => normalizeText(value))
        .filter(Boolean)
    )
  );
  const titleCandidates = dedupeRankedCandidates([
    ...(context.titleCandidates ?? []),
    ...titles.map((title, index) => toRankedCandidate(title, Math.max(0.55, 0.85 - index * 0.1), index === 0 ? "primary-title" : "derived-title"))
  ]);
  const signals = deriveSignals(context);
  const derivedIngredientSignals = context.ingredientSignals?.length
    ? context.ingredientSignals
    : signals
        .map((signal) => extractIngredientFromText(signal.content, signal.id, signal.weight, signal.source, signal.timestamp))
        .filter(Boolean) as IngredientSignal[];
  const derivedStepSignals = context.stepSignals?.length
    ? context.stepSignals
    : signals
        .filter((signal) => signal.type === "transcript" || signal.type === "caption" || signal.type === "ocr")
        .map((signal) => extractStepFromText(signal.content, signal.id, signal.weight, signal.source, signal.timestamp))
        .filter(Boolean) as StepSignal[];

  return {
    ...context,
    title: titles[0] ?? context.title ?? null,
    creator: creators[0] ?? context.creator ?? null,
    titles,
    creators,
    titleCandidates,
    thumbnailCandidates,
    transcriptSegments: deriveTranscriptSegments(context),
    ocrBlocks: deriveOcrBlocks(context),
    signals,
    ingredientSignals: derivedIngredientSignals,
    stepSignals: derivedStepSignals
  };
};

const mergeSupportingSignals = (left: string[], right: string[]) => Array.from(new Set([...left, ...right]));

const findIngredientCandidateKey = (
  candidateMap: Map<string, CandidateIngredient>,
  ingredientName: string
) => {
  const key = canonicalize(ingredientName);
  if (candidateMap.has(key)) {
    return key;
  }

  for (const [existingKey, existing] of candidateMap.entries()) {
    const existingName = canonicalize(existing.name);
    if (
      existingKey.includes(key) ||
      key.includes(existingKey) ||
      existingName.includes(key) ||
      key.includes(existingName)
    ) {
      return existingKey;
    }
  }

  return key;
};

const findStepCandidateKey = (
  candidateMap: Map<string, CandidateStep>,
  step: Pick<CandidateStep, "instruction" | "actionVerb" | "object">
) => {
  const key = canonicalize(step.instruction);
  if (candidateMap.has(key)) {
    return key;
  }

  for (const [existingKey, existing] of candidateMap.entries()) {
    const existingInstruction = canonicalize(existing.instruction);
    const sameActionObject =
      Boolean(existing.actionVerb) &&
      Boolean(step.actionVerb) &&
      existing.actionVerb === step.actionVerb &&
      Boolean(existing.object) &&
      Boolean(step.object) &&
      canonicalize(existing.object ?? "") === canonicalize(step.object ?? "");

    if (
      existingInstruction.includes(key) ||
      key.includes(existingInstruction) ||
      sameActionObject
    ) {
      return existingKey;
    }
  }

  return key;
};

const buildIngredientCandidates = (context: RawRecipeContext, signals: EvidenceSignal[]): CandidateIngredient[] => {
  const hydrated = hydrateEvidenceContext(context);
  const candidateMap = new Map<string, CandidateIngredient>();
  const metadataIngredientHints = Array.isArray((hydrated.metadata as { ingredientHints?: unknown } | null)?.ingredientHints)
    ? ((hydrated.metadata as { ingredientHints: Record<string, unknown>[] }).ingredientHints ?? [])
    : [];

  const allSignals = [
    ...(hydrated.ingredientSignals ?? []),
    ...metadataIngredientHints.map((hint, index) => ({
      id: `hint-ingredient-${index + 1}`,
      name: String(hint.name ?? "Ingredient"),
      quantity: typeof hint.quantity === "string" ? hint.quantity : hint.quantity == null ? null : String(hint.quantity),
      unit: typeof hint.unit === "string" ? normalizeUnit(hint.unit) : null,
      note: typeof hint.note === "string" ? hint.note : null,
      weight: Boolean(hint.inferred) ? 0.42 : 0.88,
      source: "metadata-hint",
      sourceSignalIds: [`metadata-hint-${index + 1}`]
    }))
  ];

  allSignals.forEach((signal) => {
    const key = findIngredientCandidateKey(candidateMap, signal.name);
    const existing = candidateMap.get(key);
    const confidence = Math.max(0.2, Math.min(0.98, signal.weight));
    if (!existing) {
      candidateMap.set(key, {
        id: signal.id,
        name: signal.name,
        quantity: signal.quantity ?? null,
        unit: signal.unit ?? null,
        note: signal.note ?? null,
        confidence,
        uncertain: confidence < 0.56 || !signal.quantity,
        supportingSignals: [...signal.sourceSignalIds]
      });
      return;
    }

    candidateMap.set(key, {
      ...existing,
      quantity: existing.quantity ?? signal.quantity ?? null,
      unit: existing.unit ?? signal.unit ?? null,
      note: existing.note ?? signal.note ?? null,
      confidence: Math.min(0.99, Math.max(existing.confidence, confidence) + 0.08),
      uncertain: existing.uncertain && confidence < 0.7 && !signal.quantity,
      supportingSignals: mergeSupportingSignals(existing.supportingSignals, signal.sourceSignalIds)
    });
  });

  signals
    .filter((signal) => signal.type === "transcript" || signal.type === "caption" || signal.type === "ocr")
    .forEach((signal) => {
      const parsed = extractIngredientFromText(signal.content, signal.id, signal.weight, signal.source, signal.timestamp);
      if (!parsed) {
        return;
      }

      const key = findIngredientCandidateKey(candidateMap, parsed.name);
      const existing = candidateMap.get(key);
      const confidence = Math.max(0.2, Math.min(0.95, parsed.weight - (signal.type === "ocr" ? 0.1 : 0)));
      if (!existing) {
        candidateMap.set(key, {
          id: parsed.id,
          name: parsed.name,
          quantity: parsed.quantity ?? null,
          unit: parsed.unit ?? null,
          note: parsed.note ?? null,
          confidence,
          uncertain: confidence < 0.58 || !parsed.quantity,
          supportingSignals: [...parsed.sourceSignalIds]
        });
        return;
      }

      candidateMap.set(key, {
        ...existing,
        quantity: existing.quantity ?? parsed.quantity ?? null,
        unit: existing.unit ?? parsed.unit ?? null,
        confidence: Math.min(0.99, Math.max(existing.confidence, confidence)),
        uncertain: existing.uncertain && confidence < 0.7 && !parsed.quantity,
        supportingSignals: mergeSupportingSignals(existing.supportingSignals, parsed.sourceSignalIds)
      });
    });

  return Array.from(candidateMap.values()).sort((left, right) => right.confidence - left.confidence);
};

const buildStepCandidates = (context: RawRecipeContext, signals: EvidenceSignal[]): CandidateStep[] => {
  const hydrated = hydrateEvidenceContext(context);
  const candidateMap = new Map<string, CandidateStep>();
  const metadataStepHints = Array.isArray((hydrated.metadata as { stepHints?: unknown } | null)?.stepHints)
    ? ((hydrated.metadata as { stepHints: Record<string, unknown>[] }).stepHints ?? [])
    : [];

  const allSteps = [
    ...(hydrated.stepSignals ?? []),
    ...metadataStepHints.map((hint, index) => ({
      id: `hint-step-${index + 1}`,
      instruction: String(hint.instruction ?? "Complete this step."),
      action: inferActionVerb(String(hint.instruction ?? "")),
      object: FOOD_CUES.find((cue) => canonicalize(String(hint.instruction ?? "")).includes(cue)) ?? null,
      weight: Boolean(hint.inferred) ? 0.45 : 0.88,
      source: "metadata-hint",
      sourceSignalIds: [`metadata-step-${index + 1}`],
      timestamp: typeof hint.timestamp === "number" ? hint.timestamp : undefined,
      durationMinutes:
        typeof hint.durationMinutes === "number"
          ? hint.durationMinutes
          : typeof hint.duration_minutes === "number"
            ? hint.duration_minutes
            : null
    }))
  ];

  allSteps.forEach((signal, index) => {
    const key = findStepCandidateKey(candidateMap, {
      instruction: signal.instruction,
      actionVerb: signal.action ?? null,
      object: signal.object ? String(signal.object).replace(/\b\w/g, (char) => char.toUpperCase()) : null
    });
    const confidence = Math.max(0.25, Math.min(0.98, signal.weight));
    const existing = candidateMap.get(key);
    const durationMinutes = "durationMinutes" in signal && typeof signal.durationMinutes === "number" ? signal.durationMinutes : null;

    if (!existing) {
      candidateMap.set(key, {
        id: signal.id,
        instruction: signal.instruction,
        orderHint: index + 1,
        actionVerb: signal.action ?? null,
        object: signal.object ? String(signal.object).replace(/\b\w/g, (char) => char.toUpperCase()) : null,
        durationMinutes,
        timestamp: signal.timestamp ?? null,
        confidence,
        uncertain: confidence < 0.6 || !signal.action,
        supportingSignals: [...signal.sourceSignalIds]
      });
      return;
    }

    candidateMap.set(key, {
      ...existing,
      durationMinutes: existing.durationMinutes ?? durationMinutes,
      timestamp: existing.timestamp ?? signal.timestamp ?? null,
      confidence: Math.min(0.99, Math.max(existing.confidence, confidence)),
      uncertain: existing.uncertain && confidence < 0.72,
      supportingSignals: mergeSupportingSignals(existing.supportingSignals, signal.sourceSignalIds)
    });
  });

  signals
    .filter((signal) => signal.type === "transcript" || signal.type === "caption" || signal.type === "ocr")
    .forEach((signal) => {
      const parsed = extractStepFromText(signal.content, signal.id, signal.weight, signal.source, signal.timestamp);
      if (!parsed) {
        return;
      }
      const key = findStepCandidateKey(candidateMap, {
        instruction: parsed.instruction,
        actionVerb: parsed.action ?? null,
        object: parsed.object ?? null
      });
      const existing = candidateMap.get(key);
      const confidence = Math.max(0.25, Math.min(0.94, parsed.weight));

      if (!existing) {
        candidateMap.set(key, {
          id: parsed.id,
          instruction: parsed.instruction,
          orderHint: candidateMap.size + 1,
          actionVerb: parsed.action ?? null,
          object: parsed.object ?? null,
          durationMinutes: null,
          timestamp: parsed.timestamp ?? null,
          confidence,
          uncertain: confidence < 0.6 || !parsed.object,
          supportingSignals: [...parsed.sourceSignalIds]
        });
        return;
      }

      candidateMap.set(key, {
        ...existing,
        confidence: Math.min(0.99, Math.max(existing.confidence, confidence)),
        uncertain: existing.uncertain && confidence < 0.7,
        supportingSignals: mergeSupportingSignals(existing.supportingSignals, parsed.sourceSignalIds)
      });
    });

  return Array.from(candidateMap.values()).sort((left, right) => {
    const leftOrder = left.timestamp ?? left.orderHint ?? Number.MAX_SAFE_INTEGER;
    const rightOrder = right.timestamp ?? right.orderHint ?? Number.MAX_SAFE_INTEGER;
    return leftOrder - rightOrder;
  });
};

const buildMetadataCandidates = (context: RawRecipeContext, signals: EvidenceSignal[]): CandidateMetadata => {
  const hydrated = hydrateEvidenceContext(context);
  const hints = (hydrated.metadata ?? {}) as {
    servingsHint?: number;
    prepTimeMinutesHint?: number;
    cookTimeMinutesHint?: number;
  };

  const titleCandidates = dedupeRankedCandidates([
    ...(hydrated.titleCandidates ?? []),
    ...signals
      .filter((signal) => signal.type === "metadata" || signal.type === "caption")
      .slice(0, 4)
      .map((signal) => toRankedCandidate(signal.content, signal.weight, signal.source))
  ]);
  const creatorCandidates = dedupeRankedCandidates(
    (hydrated.creators ?? []).map((creator, index) => toRankedCandidate(creator, Math.max(0.5, 0.8 - index * 0.1), "creator"))
  );

  const stepCount = buildStepCandidates(hydrated, signals).length;
  const ingredientCount = buildIngredientCandidates(hydrated, signals).length;

  const servingsValue = hints.servingsHint ?? (ingredientCount >= 6 ? 4 : ingredientCount >= 3 ? 2 : null);
  const prepValue = hints.prepTimeMinutesHint ?? (stepCount >= 3 ? 12 : null);
  const cookValue = hints.cookTimeMinutesHint ?? (stepCount >= 3 ? stepCount * 6 : null);
  const totalValue = typeof prepValue === "number" && typeof cookValue === "number" ? prepValue + cookValue : null;

  return {
    titleCandidates,
    creatorCandidates,
    servings: {
      value: servingsValue,
      confidence: hints.servingsHint ? 0.9 : servingsValue ? 0.46 : 0,
      supportingSignals: servingsValue ? ["metadata-servings"] : []
    },
    prepTimeMinutes: {
      value: prepValue,
      confidence: hints.prepTimeMinutesHint ? 0.86 : prepValue ? 0.42 : 0,
      supportingSignals: prepValue ? ["metadata-prep-time"] : []
    },
    cookTimeMinutes: {
      value: cookValue,
      confidence: hints.cookTimeMinutesHint ? 0.86 : cookValue ? 0.42 : 0,
      supportingSignals: cookValue ? ["metadata-cook-time"] : []
    },
    totalTimeMinutes: {
      value: totalValue,
      confidence: totalValue ? 0.44 : 0,
      supportingSignals: totalValue ? ["metadata-total-time"] : []
    }
  };
};

export const aggregateEvidence = (context: RawRecipeContext): AggregatedEvidence => {
  const hydrated = hydrateEvidenceContext(context);
  const normalizedSignals = deriveSignals(hydrated)
    .map((signal) => ({
      ...signal,
      content: normalizeText(signal.content),
      weight: Math.max(0.1, Math.min(1, signal.weight))
    }))
    .filter((signal, index, signals) => signals.findIndex((candidate) => candidate.id === signal.id) === index);

  return {
    ingredients: buildIngredientCandidates(hydrated, normalizedSignals),
    steps: buildStepCandidates(hydrated, normalizedSignals),
    metadata: buildMetadataCandidates(hydrated, normalizedSignals),
    normalizedSignals
  };
};

const aggregateSourceEvidence = (context: RawRecipeContext): SourceEvidence => {
  const hydrated = hydrateEvidenceContext(context);
  const aggregated = aggregateEvidence(hydrated);
  const transcriptText = normalizeText(hydrated.transcript ?? hydrated.transcriptSegments?.map((segment) => segment.text).join(" "));
  const captionText = normalizeText(hydrated.caption);
  const ocrText = normalizeText(hydrated.ocrBlocks?.map((block) => block.text).join(" ") ?? hydrated.ocrText?.join(" "));
  const commentsText = normalizeText(hydrated.comments?.join(" "));
  const combinedText = [captionText, transcriptText, ocrText, commentsText].filter(Boolean).join(" ").toLowerCase();
  const cueMentions = FOOD_CUES.filter((cue) => combinedText.includes(cue));
  const signalOrigins = Array.isArray((hydrated.metadata as { signalOrigins?: unknown } | null)?.signalOrigins)
    ? ((hydrated.metadata as { signalOrigins: unknown[] }).signalOrigins.filter((item): item is string => typeof item === "string"))
    : [];

  return {
    combinedText,
    transcriptText,
    captionText,
    ocrText,
    commentsText,
    explicitQuantityMentions: aggregated.ingredients.filter((ingredient) => ingredient.quantity).length,
    cueMentions,
    hasStrongTranscript: transcriptText.length > 120 || (hydrated.transcriptSegments?.length ?? 0) >= 3,
    hasAnyTextSignals: Boolean(combinedText),
    signalOriginCount: signalOrigins.length,
    lowQualitySignalCount: hydrated.signals?.filter((signal) => signal.weight < 0.4).length ?? 0,
    actionVerbCount: aggregated.steps.filter((step) => step.actionVerb).length,
    titles: hydrated.titles ?? [],
    creators: hydrated.creators ?? [],
    thumbnailCandidates: hydrated.thumbnailCandidates ?? []
  };
};

const getThumbnailFromContext = (context: RawRecipeContext) =>
  selectBestThumbnailCandidate(context.thumbnailCandidates ?? [], context.platform) ??
  context.thumbnailUrl ??
  (context.platform === "youtube"
    ? getYouTubeThumbnailFromVideoId(context.sourceUrl)
    : context.platform === "tiktok"
      ? buildTikTokThumbnailUrl(context.sourceUrl)
      : buildInstagramThumbnailUrl(context.sourceUrl));

export const generateFallbackThumbnailStyle = (recipeTitle: string, platform: string) => {
  const title = recipeTitle.toLowerCase();
  if (title.includes("salmon") || title.includes("honey")) {
    return "amber-glaze";
  }
  if (title.includes("pasta") || title.includes("cream")) {
    return "warm-cream";
  }
  if (platform === "youtube") {
    return "golden-sear";
  }
  if (platform === "tiktok") {
    return "honey-pop";
  }
  return "sunlit-skillet";
};

const createMockContext = (sourceUrl: string, platform: SourcePlatform): RawRecipeContext => {
  const common = hydrateEvidenceContext({
    sourceUrl,
    platform,
    title:
      platform === "youtube"
        ? "Creamy Garlic Chicken Orzo"
        : platform === "tiktok"
          ? "Crispy Hot Honey Salmon"
          : "One Pan Tuscan Pasta",
    creator: platform === "youtube" ? "Cooksy Creator" : platform === "tiktok" ? "@weeknightbites" : "cooksy.kitchen",
    caption:
      platform === "youtube"
        ? "One-pan creamy garlic chicken orzo with parmesan and spinach."
        : platform === "tiktok"
          ? "Crispy salmon, sticky hot honey glaze, and herby rice for the easiest dinner."
          : "One pan creamy tuscan pasta with sun-dried tomatoes and spinach.",
    transcript:
      platform === "youtube"
        ? "Season the chicken, sear until golden, then add garlic, butter, and dry orzo. Pour in chicken stock and cream, simmer until tender, then finish with spinach and parmesan."
        : platform === "tiktok"
          ? "Pat the salmon dry, season it well, and roast until crisp. Warm butter, garlic, chili flakes, and honey for the glaze, then spoon it over the salmon and serve with rice."
          : "Saute garlic and sun-dried tomatoes, add pasta, stock, and cream, then simmer until silky. Finish with parmesan and spinach.",
    ocrText:
      platform === "youtube"
        ? ["one pan", "garlic chicken", "orzo"]
        : platform === "tiktok"
          ? ["hot honey salmon", "crispy", "easy dinner"]
          : ["tuscan pasta", "one pan", "creamy"],
    comments:
      platform === "youtube"
        ? ["Need exact garlic amount", "Looks like about 4 servings"]
        : platform === "tiktok"
          ? ["What temp did you roast at?", "Saved for this week"]
          : ["How much stock?", "Perfect date night dinner"],
    metadata:
      platform === "youtube"
        ? {
            ingredientHints: [
              { name: "Chicken thighs", quantity: "6", note: "boneless skinless" },
              { name: "Garlic", inferred: true },
              { name: "Orzo", quantity: "1", unit: "cup" },
              { name: "Chicken stock", quantity: "2", unit: "cups" },
              { name: "Heavy cream", quantity: "1", unit: "cup" },
              { name: "Parmesan", quantity: "1", unit: "cup", note: "finely grated" },
              { name: "Spinach", quantity: "2", unit: "cups" }
            ],
            stepHints: [
              { instruction: "Season and sear the chicken in a large skillet until deeply golden.", durationMinutes: 8 },
              { instruction: "Add garlic and orzo, then stir in stock and cream and simmer until the pasta is tender.", durationMinutes: 14 },
              { instruction: "Fold in spinach and parmesan, then return the chicken to the pan to finish.", durationMinutes: 5 }
            ],
            servingsHint: 4,
            prepTimeMinutesHint: 12,
            cookTimeMinutesHint: 27
          }
        : platform === "tiktok"
          ? {
              ingredientHints: [
                { name: "Salmon fillets", quantity: "4" },
                { name: "Honey", quantity: "3", unit: "tbsp" },
                { name: "Butter", quantity: "2", unit: "tbsp" },
                { name: "Garlic", inferred: true },
                { name: "Chili flakes", quantity: "1", unit: "tsp" },
                { name: "Cooked rice", quantity: "4", unit: "cups" }
              ],
              stepHints: [
                { instruction: "Roast the salmon until just cooked and crisp around the edges.", durationMinutes: 12, inferred: true },
                { instruction: "Warm the glaze ingredients together until glossy and spoonable.", durationMinutes: 4 },
                { instruction: "Coat the salmon with hot honey glaze and serve over rice.", durationMinutes: 3 }
              ],
              servingsHint: 4,
              prepTimeMinutesHint: 10,
              cookTimeMinutesHint: 18
            }
          : {
              ingredientHints: [
                { name: "Pasta", quantity: "12", unit: "oz" },
                { name: "Garlic", inferred: true },
                { name: "Sun-dried tomatoes", quantity: "1", unit: "cup" },
                { name: "Vegetable stock", quantity: "3", unit: "cups" },
                { name: "Heavy cream", quantity: "1", unit: "cup" },
                { name: "Parmesan", quantity: "0.75", unit: "cup" },
                { name: "Spinach", quantity: "3", unit: "cups" }
              ],
              stepHints: [
                { instruction: "Cook the garlic and tomatoes until fragrant.", durationMinutes: 4 },
                { instruction: "Add pasta, stock, and cream and simmer until the pasta is tender.", durationMinutes: 15 },
                { instruction: "Stir in spinach and parmesan and serve immediately.", durationMinutes: 3 }
              ],
              servingsHint: 4,
              prepTimeMinutesHint: 10,
              cookTimeMinutesHint: 20
            },
    thumbnailUrl:
      platform === "youtube"
        ? getYouTubeThumbnailFromVideoId(sourceUrl)
        : platform === "tiktok"
          ? buildTikTokThumbnailUrl(sourceUrl)
          : buildInstagramThumbnailUrl(sourceUrl)
  });
  return common;
};

const asRawRecipeContext = (value: unknown): RawRecipeContext | null => {
  if (!value || typeof value !== "object") {
    return null;
  }
  const candidate = value as Record<string, unknown>;
  if (typeof candidate.sourceUrl !== "string" || typeof candidate.platform !== "string") {
    return null;
  }

  return hydrateEvidenceContext({
    sourceUrl: candidate.sourceUrl,
    platform: candidate.platform as SourcePlatform,
    title: typeof candidate.title === "string" ? candidate.title : null,
    creator: typeof candidate.creator === "string" ? candidate.creator : null,
    caption: typeof candidate.caption === "string" ? candidate.caption : null,
    transcript: typeof candidate.transcript === "string" ? candidate.transcript : null,
    ocrText: Array.isArray(candidate.ocrText) ? candidate.ocrText.filter((item): item is string => typeof item === "string") : null,
    comments: Array.isArray(candidate.comments) ? candidate.comments.filter((item): item is string => typeof item === "string") : null,
    metadata: candidate.metadata && typeof candidate.metadata === "object" ? (candidate.metadata as Record<string, unknown>) : null,
    thumbnailUrl: typeof candidate.thumbnailUrl === "string" ? candidate.thumbnailUrl : null,
    signals: Array.isArray(candidate.signals) ? (candidate.signals as EvidenceSignal[]) : undefined,
    transcriptSegments: Array.isArray(candidate.transcriptSegments) ? (candidate.transcriptSegments as TranscriptSegment[]) : undefined,
    ocrBlocks: Array.isArray(candidate.ocrBlocks) ? (candidate.ocrBlocks as OcrBlock[]) : undefined,
    thumbnailCandidates: Array.isArray(candidate.thumbnailCandidates)
      ? candidate.thumbnailCandidates.filter((item): item is string => typeof item === "string")
      : undefined,
    creators: Array.isArray(candidate.creators) ? candidate.creators.filter((item): item is string => typeof item === "string") : undefined,
    titles: Array.isArray(candidate.titles) ? candidate.titles.filter((item): item is string => typeof item === "string") : undefined
  });
};

export const inferPlatformFromUrl = (value: string): SourcePlatform | null => {
  try {
    const url = new URL(value);
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
  } catch {
    return null;
  }
  return null;
};

export const extractRecipeContextForImport = async ({
  sourceUrl,
  sourcePlatform,
  sourcePayload
}: {
  sourceUrl: string;
  sourcePlatform: SourcePlatform;
  sourcePayload?: Record<string, unknown> | null;
}): Promise<RawRecipeContext> => {
  const storedContext = asRawRecipeContext(sourcePayload);
  const baseContext = storedContext?.platform === sourcePlatform ? storedContext : createMockContext(sourceUrl, sourcePlatform);

  if (sourcePlatform !== "youtube") {
    const signals = await fetchSocialPageSignals({
      sourceUrl,
      platform: sourcePlatform,
      creatorHint: typeof baseContext.creator === "string" ? baseContext.creator : null
    }).catch(() => null);

    return hydrateEvidenceContext({
      ...baseContext,
      sourceUrl,
      platform: sourcePlatform,
      title: signals?.title ?? baseContext.title,
      creator: signals?.creator ?? baseContext.creator,
      caption: signals?.description ?? baseContext.caption,
      transcript: signals?.transcript ?? baseContext.transcript,
      thumbnailUrl: signals?.thumbnailUrl ?? baseContext.thumbnailUrl ?? getThumbnailFromContext(baseContext),
      metadata: {
        ...(baseContext.metadata ?? {}),
        signalOrigins: signals?.signalOrigins ?? ["mock-fallback"],
        extractionSource: signals?.signalOrigins?.includes("open-graph") || signals?.signalOrigins?.includes("json-ld") ? "social-page" : "mock-fallback"
      },
      titles: Array.from(new Set([signals?.title ?? null, ...(baseContext.titles ?? [])].filter(Boolean) as string[])),
      creators: Array.from(new Set([signals?.creator ?? null, ...(baseContext.creators ?? [])].filter(Boolean) as string[])),
      thumbnailCandidates: Array.from(
        new Set([signals?.thumbnailUrl ?? null, baseContext.thumbnailUrl ?? null, ...(baseContext.thumbnailCandidates ?? [])].filter(Boolean) as string[])
      )
    });
  }

  try {
    const [oembed, watchSignals] = await Promise.all([fetchYouTubeOEmbedMetadata(sourceUrl), fetchYouTubeWatchPageSignals(sourceUrl).catch(() => null)]);
    return hydrateEvidenceContext({
      ...baseContext,
      sourceUrl,
      platform: sourcePlatform,
      title: oembed.title ?? watchSignals?.title ?? baseContext.title,
      creator: oembed.author_name ?? watchSignals?.creator ?? baseContext.creator,
      caption: watchSignals?.description ?? baseContext.caption,
      transcript: watchSignals?.transcript ?? baseContext.transcript,
      transcriptSegments: watchSignals?.transcriptSegments ?? baseContext.transcriptSegments,
      thumbnailUrl: oembed.thumbnail_url ?? baseContext.thumbnailUrl ?? getThumbnailFromContext(baseContext),
      thumbnailCandidates: Array.from(
        new Set(
          [
            oembed.thumbnail_url ?? null,
            baseContext.thumbnailUrl ?? null,
            ...(baseContext.thumbnailCandidates ?? []),
            getYouTubeThumbnailFromVideoId(sourceUrl)
          ].filter(Boolean) as string[]
        )
      ),
      metadata: {
        ...(baseContext.metadata ?? {}),
        videoId: getYouTubeVideoId(sourceUrl),
        authorUrl: oembed.author_url ?? null,
        watchSignalsAvailable: Boolean(watchSignals?.title || watchSignals?.description || watchSignals?.transcript),
        captionTrackCount: watchSignals?.captionTracks?.length ?? 0,
        signalOrigins: ["oembed", ...(watchSignals?.title || watchSignals?.description || watchSignals?.transcript ? ["watch-page"] : [])],
        extractionSource:
          oembed && (watchSignals?.description || watchSignals?.transcript)
            ? "youtube-oembed+watch"
            : oembed
              ? "youtube-oembed"
              : watchSignals?.description || watchSignals?.transcript
                ? "youtube-watch"
                : "mock-fallback"
      },
      titles: Array.from(new Set([oembed.title ?? null, watchSignals?.title ?? null, ...(baseContext.titles ?? [])].filter(Boolean) as string[])),
      creators: Array.from(
        new Set([oembed.author_name ?? null, watchSignals?.creator ?? null, ...(baseContext.creators ?? [])].filter(Boolean) as string[])
      )
    });
  } catch {
    return hydrateEvidenceContext({
      ...baseContext,
      sourceUrl,
      platform: sourcePlatform,
      thumbnailUrl: baseContext.thumbnailUrl ?? getThumbnailFromContext(baseContext),
      metadata: {
        ...(baseContext.metadata ?? {}),
        videoId: getYouTubeVideoId(sourceUrl),
        signalOrigins: ["mock-fallback"],
        extractionSource: "mock-fallback"
      }
    });
  }
};

const toTitleCase = (value: string) => value.replace(/\b\w/g, (char) => char.toUpperCase());

export const extractIngredientsFromContext = async (context: RawRecipeContext): Promise<Ingredient[]> => {
  const aggregated = aggregateEvidence(context);
  return aggregated.ingredients.map((ingredient, index) => ({
    id: ingredient.id || buildId("ingredient", index),
    name: toTitleCase(ingredient.name),
    quantity: ingredient.quantity ?? null,
    unit: ingredient.unit ?? null,
    note: ingredient.note ?? null,
    inferred: Boolean(ingredient.uncertain)
  }));
};

const normalizeInstruction = (value: string) => {
  const normalized = value.replace(/\s+/g, " ").trim();
  if (!normalized) {
    return "";
  }
  const withCapital = normalized.charAt(0).toUpperCase() + normalized.slice(1);
  return /[.!?]$/.test(withCapital) ? withCapital : `${withCapital}.`;
};

const ensureInstructionObject = (instruction: string, fallbackObject?: string | null) => {
  if (fallbackObject && !new RegExp(`\\b${fallbackObject.toLowerCase()}\\b`, "i").test(instruction)) {
    return normalizeInstruction(`${instruction.replace(/[.!?]$/, "")} with ${fallbackObject.toLowerCase()}`);
  }
  return normalizeInstruction(instruction);
};

export const extractStepsFromContext = async (context: RawRecipeContext): Promise<RecipeStep[]> => {
  const aggregated = aggregateEvidence(context);
  const hasMetadataStepHints = aggregated.steps.some((step) =>
    step.supportingSignals.some((signalId) => signalId.startsWith("metadata-step-"))
  );
  const seen = new Set<string>();
  const candidateSteps = (hasMetadataStepHints
    ? aggregated.steps.filter((step) => step.supportingSignals.some((signalId) => signalId.startsWith("metadata-step-")))
    : aggregated.steps
  )
    .map((step) => ({
      ...step,
      instruction: ensureInstructionObject(step.instruction, step.object)
    }))
    .filter((step) => {
      const key = canonicalize(step.instruction);
      if (seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    })
    .map((step, index) => ({
      id: step.id || buildId("step", index),
      order: index + 1,
      instruction: step.instruction,
      durationMinutes: step.durationMinutes ?? null,
      temperature: null,
      inferred: Boolean(step.uncertain)
    }));

  if (candidateSteps.length) {
    return candidateSteps;
  }

  const fallbackObject = aggregated.ingredients[0]?.name ?? "ingredients";
  const secondObject = aggregated.ingredients[1]?.name ?? "the sauce";

  return [
    {
      id: buildId("step", 0),
      order: 1,
      instruction: normalizeInstruction(`Prep ${fallbackObject.toLowerCase()} and season to taste`),
      durationMinutes: 8,
      temperature: null,
      inferred: true
    },
    {
      id: buildId("step", 1),
      order: 2,
      instruction: normalizeInstruction(`Cook ${fallbackObject.toLowerCase()} with ${secondObject.toLowerCase()} until ready, then serve`),
      durationMinutes: 12,
      temperature: null,
      inferred: true
    }
  ];
};

export const extractRecipeMetadata = async (context: RawRecipeContext) => {
  const aggregated = aggregateEvidence(context);
  const evidence = aggregateSourceEvidence(context);
  const title = aggregated.metadata.titleCandidates[0]?.value ?? context.title?.trim() ?? `${context.platform} recipe import`;
  const sourceCreator = aggregated.metadata.creatorCandidates[0]?.value ?? context.creator?.trim() ?? null;
  const description =
    context.caption?.trim() || context.transcript?.slice(0, 180) || (evidence.commentsText ? evidence.commentsText.slice(0, 180) : null) || "Imported from social cooking content.";
  return {
    title,
    description,
    servings: aggregated.metadata.servings?.value ?? null,
    prepTimeMinutes: aggregated.metadata.prepTimeMinutes?.value ?? null,
    cookTimeMinutes: aggregated.metadata.cookTimeMinutes?.value ?? null,
    totalTimeMinutes: aggregated.metadata.totalTimeMinutes?.value ?? null,
    sourceCreator,
    sourceTitle: context.title ?? title
  };
};

export const inferMissingRecipeFields = async (
  partialRecipe: Omit<ReconstructionResult, "confidenceScore" | "confidenceReport" | "validationWarnings" | "inferredFields" | "missingFields">,
  context: RawRecipeContext
) => {
  const evidence = aggregateSourceEvidence(context);
  const inferredFields: string[] = [];
  const missingFields: string[] = [];
  const metadataIngredientHints = Array.isArray((context.metadata as { ingredientHints?: unknown } | null)?.ingredientHints)
    ? ((context.metadata as { ingredientHints: Record<string, unknown>[] }).ingredientHints ?? [])
    : [];

  metadataIngredientHints.forEach((hint) => {
    if (hint.inferred && typeof hint.name === "string") {
      inferredFields.push(`${hint.name.replace(/\b\w/g, (char: string) => char.toUpperCase())} inferred from partial source cues`);
    }
  });

  const ingredients = partialRecipe.ingredients.map((ingredient) => {
    if (ingredient.quantity) {
      return ingredient;
    }
    if (/garlic/i.test(ingredient.name)) {
      inferredFields.push(`${ingredient.name} quantity inferred`);
      return { ...ingredient, quantity: "4", unit: ingredient.unit ?? "cloves", inferred: true };
    }
    missingFields.push(`${ingredient.name} quantity not provided`);
    return ingredient;
  });

  const steps = partialRecipe.steps.map((step) => {
    const nextStep = { ...step };
    if (!nextStep.durationMinutes && /simmer|roast|bake|cook/i.test(nextStep.instruction)) {
      nextStep.durationMinutes = /simmer/i.test(nextStep.instruction) ? 12 : /roast|bake/i.test(nextStep.instruction) ? 15 : 8;
      nextStep.inferred = true;
      inferredFields.push(`Timing inferred for step ${step.order}`);
    }
    if (!nextStep.temperature && /oven|bake|roast/i.test(nextStep.instruction)) {
      missingFields.push(`Temperature missing for step ${step.order}`);
    }
    return nextStep;
  });

  const servings = partialRecipe.servings ?? (ingredients.length >= 5 ? 4 : ingredients.length >= 3 ? 2 : null);
  if (partialRecipe.servings == null && servings != null) {
    inferredFields.push("Serving size inferred");
  }
  const prepTimeMinutes = partialRecipe.prepTimeMinutes ?? (evidence.hasAnyTextSignals ? 12 : null);
  if (partialRecipe.prepTimeMinutes == null && prepTimeMinutes != null) {
    inferredFields.push("Prep time inferred");
  }
  const cookTimeMinutes = partialRecipe.cookTimeMinutes ?? (steps.length ? steps.reduce((sum, step) => sum + (step.durationMinutes ?? 0), 0) || null : null);
  if (partialRecipe.cookTimeMinutes == null && cookTimeMinutes != null) {
    inferredFields.push("Cook time inferred");
  }
  const totalTimeMinutes =
    partialRecipe.totalTimeMinutes ?? (typeof prepTimeMinutes === "number" && typeof cookTimeMinutes === "number" ? prepTimeMinutes + cookTimeMinutes : null);
  if (!evidence.hasAnyTextSignals) {
    missingFields.push("Very little source text was available");
  }

  return {
    ...partialRecipe,
    ingredients,
    steps,
    servings,
    prepTimeMinutes,
    cookTimeMinutes,
    totalTimeMinutes,
    inferredFields: Array.from(new Set(inferredFields)),
    missingFields: Array.from(new Set(missingFields))
  };
};

export const validateRecipe = (recipe: Omit<ReconstructionResult, "rawExtraction" | "confidenceReport"> & { sourceUrl: string; sourcePlatform: SourcePlatform }) => {
  const warnings: string[] = [];
  if (!recipe.title.trim()) {
    warnings.push("Recipe title is missing");
  }
  if (recipe.ingredients.length < 1) {
    warnings.push("Recipe needs at least one ingredient");
  }
  if (recipe.steps.length < 1) {
    warnings.push("Recipe needs at least one step");
  }
  recipe.steps.forEach((step, index) => {
    if (step.order !== index + 1) {
      warnings.push("Recipe steps must stay in sequential order");
    }
    if (!step.instruction.trim()) {
      warnings.push(`Step ${index + 1} has no usable instruction`);
    }
  });
  const quantifiedIngredients = recipe.ingredients.filter((ingredient) => ingredient.quantity);
  if (recipe.ingredients.length && quantifiedIngredients.length / recipe.ingredients.length < 0.5) {
    warnings.push("More than half of the ingredients are missing explicit quantities");
  }
  if (typeof recipe.servings === "number" && (recipe.servings < 1 || recipe.servings > 12)) {
    warnings.push("Serving size looks implausible");
  }
  if (typeof recipe.totalTimeMinutes === "number" && recipe.totalTimeMinutes > 300) {
    warnings.push("Total cook time looks unusually long");
  }
  if (!recipe.steps.every((step) => /add|bake|boil|coat|cook|finish|fold|mix|pour|roast|season|sear|serve|simmer|stir|whisk/i.test(step.instruction))) {
    warnings.push("Some steps are still vague and may need review");
  }
  return Array.from(new Set(warnings));
};

export const scoreRecipeConfidence = (
  recipe: Omit<ReconstructionResult, "rawExtraction">,
  context: RawRecipeContext
): ConfidenceReport => {
  const evidence = aggregateSourceEvidence(context);
  const aggregated = aggregateEvidence(context);
  const warnings: string[] = [];
  const lowConfidenceAreas: string[] = [];
  const missingFields = [...recipe.missingFields];

  const transcriptStrength = evidence.hasStrongTranscript ? 0.18 : evidence.hasAnyTextSignals ? 0.08 : 0;
  const metadataStrength = recipe.sourceTitle ? 0.05 : 0;
  const creatorStrength = recipe.sourceCreator ? 0.03 : 0;
  const thumbnailStrength = recipe.thumbnailUrl ? 0.03 : 0;
  const ingredientAgreement = aggregated.ingredients.length
    ? aggregated.ingredients.reduce((sum, ingredient) => sum + ingredient.confidence, 0) / aggregated.ingredients.length
    : 0;
  const stepClarity = aggregated.steps.length
    ? aggregated.steps.reduce((sum, step) => sum + step.confidence + (step.actionVerb ? 0.08 : 0), 0) / aggregated.steps.length
    : 0;
  const ingredientStrength = ingredientAgreement * 0.14;
  const stepStrength = Math.min(0.18, stepClarity * 0.16);
  const explicitQuantityCoverage = recipe.ingredients.length
    ? recipe.ingredients.filter((ingredient) => ingredient.quantity).length / recipe.ingredients.length
    : 0;
  const explicitQuantityStrength = explicitQuantityCoverage * 0.1;
  const signalRichness = Math.min(0.08, evidence.signalOriginCount * 0.02 + evidence.actionVerbCount * 0.01);
  const recoveryStrength =
    aggregated.ingredients.length >= 3 && aggregated.steps.length >= 2 && (evidence.ocrText || evidence.commentsText) ? 0.08 : 0;
  const lowQualityPenalty = Math.min(0.08, evidence.lowQualitySignalCount * 0.02);
  const missingPenalty = Math.min(0.12, missingFields.length * 0.02);
  const inferredPenalty = Math.min(0.08, recipe.inferredFields.length * 0.01);
  const validationPenalty = Math.min(0.12, recipe.validationWarnings.length * 0.02);

  recipe.validationWarnings.forEach((warning) => warnings.push(warning));
  aggregated.ingredients.forEach((ingredient) => {
    if (ingredient.confidence < 0.56 || ingredient.uncertain) {
      lowConfidenceAreas.push(`Ingredient: ${ingredient.name}`);
    }
  });
  aggregated.steps.forEach((step, index) => {
    if (step.confidence < 0.6 || !step.actionVerb || !step.object) {
      lowConfidenceAreas.push(`Step ${index + 1}`);
    }
  });
  if (evidence.lowQualitySignalCount > 0) {
    warnings.push("Some recipe details came from lower-confidence sources like OCR or comments");
  }
  if (!recipe.sourceCreator) {
    lowConfidenceAreas.push("Source creator");
  }
  if (!recipe.thumbnailUrl) {
    lowConfidenceAreas.push("Recipe cover");
  }

  const score = Math.max(
    0,
    Math.min(
      1,
      0.18 +
        transcriptStrength +
        metadataStrength +
        creatorStrength +
        thumbnailStrength +
        ingredientStrength +
        stepStrength +
        signalRichness +
        explicitQuantityStrength +
        recoveryStrength -
        lowQualityPenalty -
        missingPenalty -
        inferredPenalty -
        validationPenalty
    )
  );

  return {
    score,
    warnings: Array.from(new Set(warnings)),
    missingFields: Array.from(new Set(missingFields)),
    lowConfidenceAreas: Array.from(new Set(lowConfidenceAreas))
  };
};

export const reconstructRecipe = async (context: RawRecipeContext): Promise<ReconstructionResult> => {
  const hydratedContext = hydrateEvidenceContext(context);
  const ingredients = await extractIngredientsFromContext(hydratedContext);
  const steps = await extractStepsFromContext(hydratedContext);
  const metadata = await extractRecipeMetadata(hydratedContext);

  if (ingredients.length < 1 || steps.length < 1) {
    throw new Error("Cooksy could not reconstruct enough recipe detail from this source");
  }

  const thumbnailUrl = getThumbnailFromContext(hydratedContext);
  const thumbnailSource = (thumbnailUrl ? hydratedContext.platform : "generated") as ThumbnailSource;
  const thumbnailFallbackStyle = generateFallbackThumbnailStyle(metadata.title, hydratedContext.platform);

  const inferred = await inferMissingRecipeFields(
    {
      title: metadata.title,
      description: metadata.description,
      servings: metadata.servings,
      prepTimeMinutes: metadata.prepTimeMinutes,
      cookTimeMinutes: metadata.cookTimeMinutes,
      totalTimeMinutes: metadata.totalTimeMinutes,
      ingredients,
      steps,
      thumbnailUrl,
      thumbnailSource,
      thumbnailFallbackStyle,
      sourceCreator: metadata.sourceCreator,
      sourceTitle: metadata.sourceTitle,
      rawExtraction: hydratedContext
    },
    hydratedContext
  );

  const validationWarnings = validateRecipe({
    sourceUrl: hydratedContext.sourceUrl,
    sourcePlatform: hydratedContext.platform,
    sourceCreator: inferred.sourceCreator,
    sourceTitle: inferred.sourceTitle,
    title: inferred.title,
    description: inferred.description,
    servings: inferred.servings,
    prepTimeMinutes: inferred.prepTimeMinutes,
    cookTimeMinutes: inferred.cookTimeMinutes,
    totalTimeMinutes: inferred.totalTimeMinutes,
    ingredients: inferred.ingredients,
    steps: inferred.steps,
    thumbnailUrl: inferred.thumbnailUrl,
    thumbnailSource: inferred.thumbnailSource,
    thumbnailFallbackStyle: inferred.thumbnailFallbackStyle,
    confidenceScore: 0,
    inferredFields: inferred.inferredFields,
    missingFields: inferred.missingFields,
    validationWarnings: []
  });

  const confidenceReport = scoreRecipeConfidence(
    {
      title: inferred.title,
      description: inferred.description,
      servings: inferred.servings,
      prepTimeMinutes: inferred.prepTimeMinutes,
      cookTimeMinutes: inferred.cookTimeMinutes,
      totalTimeMinutes: inferred.totalTimeMinutes,
      ingredients: inferred.ingredients,
      steps: inferred.steps,
      thumbnailUrl: inferred.thumbnailUrl,
      thumbnailSource: inferred.thumbnailSource,
      thumbnailFallbackStyle: inferred.thumbnailFallbackStyle,
      sourceCreator: inferred.sourceCreator,
      sourceTitle: inferred.sourceTitle,
      confidenceScore: 0,
      confidenceReport: {
        score: 0,
        warnings: [],
        missingFields: [],
        lowConfidenceAreas: []
      },
      inferredFields: inferred.inferredFields,
      missingFields: inferred.missingFields,
      validationWarnings
    },
    hydratedContext
  );

  return {
    title: inferred.title,
    description: inferred.description,
    servings: inferred.servings,
    prepTimeMinutes: inferred.prepTimeMinutes,
    cookTimeMinutes: inferred.cookTimeMinutes,
    totalTimeMinutes: inferred.totalTimeMinutes,
    ingredients: inferred.ingredients,
    steps: inferred.steps,
    thumbnailUrl: inferred.thumbnailUrl,
    thumbnailSource: inferred.thumbnailSource,
    thumbnailFallbackStyle: inferred.thumbnailFallbackStyle,
    sourceCreator: inferred.sourceCreator,
    sourceTitle: inferred.sourceTitle,
    confidenceScore: Math.round(confidenceReport.score * 100),
    confidenceReport,
    inferredFields: inferred.inferredFields,
    missingFields: confidenceReport.missingFields,
    validationWarnings: Array.from(new Set([...validationWarnings, ...confidenceReport.warnings])),
    rawExtraction: hydratedContext
  };
};

const combineIngredientQuantity = (ingredient: Ingredient) =>
  [ingredient.quantity, ingredient.unit].filter(Boolean).join(" ").trim() || ingredient.note || "To taste";

const confidenceLevel = (score: number): PersistedRecipe["confidence"] => (score >= 85 ? "high" : score >= 60 ? "medium" : "low");

export const buildPersistedRecipe = ({
  jobId,
  sourceUrl,
  sourcePlatform,
  reconstruction
}: {
  jobId: string;
  sourceUrl: string;
  sourcePlatform: SourcePlatform;
  reconstruction: ReconstructionResult;
}): PersistedRecipe => ({
  status: "ready",
  importJobId: jobId,
  title: reconstruction.title,
  description:
    reconstruction.description ??
    "Cooksy reconstructed this recipe from the original social cooking post so you can save and edit it later.",
  heroNote:
    reconstruction.sourceTitle ??
    reconstruction.description ??
    "Imported from social media and reconstructed for home cooking.",
  imageLabel: `${reconstruction.title} cover`,
  thumbnailUrl: reconstruction.thumbnailUrl ?? null,
  thumbnailSource: reconstruction.thumbnailSource,
  thumbnailFallbackStyle: reconstruction.thumbnailFallbackStyle ?? undefined,
  servings: reconstruction.servings ?? 2,
  prepTimeMinutes: reconstruction.prepTimeMinutes ?? 0,
  cookTimeMinutes: reconstruction.cookTimeMinutes ?? 0,
  totalTimeMinutes: reconstruction.totalTimeMinutes ?? 0,
  confidence: confidenceLevel(reconstruction.confidenceScore),
  confidenceScore: reconstruction.confidenceScore,
  confidenceNote:
    reconstruction.confidenceReport.warnings[0] ??
    reconstruction.validationWarnings[0] ??
    (reconstruction.inferredFields.length
      ? `${reconstruction.inferredFields[0]}.`
      : "Cooksy reconstructed this recipe from available source signals."),
  inferredFields: reconstruction.inferredFields,
  missingFields: reconstruction.missingFields,
  validationWarnings: reconstruction.validationWarnings,
  rawExtraction: reconstruction.rawExtraction,
  isSaved: true,
  source: {
    creator: reconstruction.sourceCreator ?? "Imported Creator",
    url: sourceUrl,
    platform: sourcePlatform
  },
  ingredients: reconstruction.ingredients.map((ingredient) => ({
    id: ingredient.id,
    name: ingredient.name,
    quantity: combineIngredientQuantity(ingredient),
    optional: ingredient.optional
  })),
  steps: reconstruction.steps.map((step) => ({
    id: step.id,
    title: `Step ${step.order}`,
    instruction: step.instruction,
    durationMinutes: step.durationMinutes ?? undefined
  })),
  tags: [
    "Imported",
    sourcePlatform === "youtube" ? "Video" : sourcePlatform === "tiktok" ? "Short Form" : "Social Save"
  ]
});
