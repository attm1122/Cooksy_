export type SourcePlatform = "youtube" | "tiktok" | "instagram";
export type ThumbnailSource = SourcePlatform | "generated";
export type SourceSignalOrigin = "oembed" | "watch-page" | "open-graph" | "json-ld" | "mock-fallback";

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
};

export type SourceSignals = {
  title?: string | null;
  description?: string | null;
  creator?: string | null;
  thumbnailUrl?: string | null;
  transcript?: string | null;
  signalOrigins: SourceSignalOrigin[];
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

const readHints = (context: RawRecipeContext): MetadataHints => ((context.metadata ?? {}) as MetadataHints);

const buildId = (prefix: string, index: number) => `${prefix}-${index + 1}`;

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

const extractCaptionTracksFromWatchHtml = (html: string): YouTubeCaptionTrack[] => {
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

const fetchYouTubeTranscriptFromTrack = async (track: YouTubeCaptionTrack) => {
  const response = await fetch(track.baseUrl);

  if (!response.ok) {
    return null;
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

const createMockContext = (sourceUrl: string, platform: SourcePlatform): RawRecipeContext => {
  if (platform === "youtube") {
    return {
      sourceUrl,
      platform,
      title: "Creamy Garlic Chicken Orzo",
      creator: "Cooksy Creator",
      caption: "One-pan creamy garlic chicken orzo with parmesan and spinach.",
      transcript:
        "Season the chicken, sear until golden, then add garlic, butter, and dry orzo. Pour in chicken stock and cream, simmer until tender, then finish with spinach and parmesan.",
      ocrText: ["one pan", "garlic chicken", "orzo"],
      comments: ["Need exact garlic amount", "Looks like about 4 servings"],
      metadata: {
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
      },
      thumbnailUrl: getYouTubeThumbnailFromVideoId(sourceUrl)
    };
  }

  if (platform === "tiktok") {
    return {
      sourceUrl,
      platform,
      title: "Crispy Hot Honey Salmon",
      creator: "@weeknightbites",
      caption: "Crispy salmon, sticky hot honey glaze, and herby rice for the easiest dinner.",
      transcript:
        "Pat the salmon dry, season it well, and roast until crisp. Warm butter, garlic, chili flakes, and honey for the glaze, then spoon it over the salmon and serve with rice.",
      ocrText: ["hot honey salmon", "crispy", "easy dinner"],
      comments: ["What temp did you roast at?", "Saved for this week"],
      metadata: {
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
      },
      thumbnailUrl: `https://picsum.photos/seed/tiktok-${slugFromTitle("crispy-hot-honey-salmon")}/1280/960`
    };
  }

  return {
    sourceUrl,
    platform,
    title: "One Pan Tuscan Pasta",
    creator: "cooksy.kitchen",
    caption: "One pan creamy tuscan pasta with sun-dried tomatoes and spinach.",
    transcript:
      "Saute garlic and sun-dried tomatoes, add pasta, stock, and cream, then simmer until silky. Finish with parmesan and spinach.",
    ocrText: ["tuscan pasta", "one pan", "creamy"],
    comments: ["How much stock?", "Perfect date night dinner"],
    metadata: {
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
    thumbnailUrl: `https://picsum.photos/seed/instagram-${slugFromTitle("one-pan-tuscan-pasta")}/1280/960`
  };
};

const asRawRecipeContext = (value: unknown): RawRecipeContext | null => {
  if (!value || typeof value !== "object") {
    return null;
  }

  const candidate = value as Record<string, unknown>;
  if (typeof candidate.sourceUrl !== "string" || typeof candidate.platform !== "string") {
    return null;
  }

  return {
    sourceUrl: candidate.sourceUrl,
    platform: candidate.platform as SourcePlatform,
    title: typeof candidate.title === "string" ? candidate.title : null,
    creator: typeof candidate.creator === "string" ? candidate.creator : null,
    caption: typeof candidate.caption === "string" ? candidate.caption : null,
    transcript: typeof candidate.transcript === "string" ? candidate.transcript : null,
    ocrText: Array.isArray(candidate.ocrText) ? candidate.ocrText.filter((item): item is string => typeof item === "string") : null,
    comments: Array.isArray(candidate.comments) ? candidate.comments.filter((item): item is string => typeof item === "string") : null,
    metadata: candidate.metadata && typeof candidate.metadata === "object" ? (candidate.metadata as Record<string, unknown>) : null,
    thumbnailUrl: typeof candidate.thumbnailUrl === "string" ? candidate.thumbnailUrl : null
  };
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

export const getThumbnailFromContext = (context: RawRecipeContext) => {
  if (context.thumbnailUrl) {
    return context.thumbnailUrl;
  }

  if (context.platform === "youtube") {
    return getYouTubeThumbnailFromVideoId(context.sourceUrl);
  }

  return null;
};

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

    return {
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
      }
    };
  }

  try {
    const [oembed, watchSignals] = await Promise.all([
      fetchYouTubeOEmbedMetadata(sourceUrl),
      fetchYouTubeWatchPageSignals(sourceUrl).catch(() => null)
    ]);

    return {
      ...baseContext,
      sourceUrl,
      platform: sourcePlatform,
      title: oembed.title ?? watchSignals?.title ?? baseContext.title,
      creator: oembed.author_name ?? watchSignals?.creator ?? baseContext.creator,
      caption: watchSignals?.description ?? baseContext.caption,
      transcript: watchSignals?.transcript ?? baseContext.transcript,
      thumbnailUrl: oembed.thumbnail_url ?? baseContext.thumbnailUrl ?? getThumbnailFromContext(baseContext),
      metadata: {
        ...(baseContext.metadata ?? {}),
        videoId: getYouTubeVideoId(sourceUrl),
        authorUrl: oembed.author_url ?? null,
        watchSignalsAvailable: Boolean(watchSignals?.description || watchSignals?.transcript),
        captionTrackCount: watchSignals?.captionTracks?.length ?? 0,
        extractionSource:
          oembed && (watchSignals?.description || watchSignals?.transcript)
            ? "youtube-oembed+watch"
            : oembed
              ? "youtube-oembed"
              : watchSignals?.description || watchSignals?.transcript
                ? "youtube-watch"
                : "mock-fallback"
      }
    };
  } catch {
    return {
      ...baseContext,
      sourceUrl,
      platform: sourcePlatform,
      thumbnailUrl: baseContext.thumbnailUrl ?? getThumbnailFromContext(baseContext),
      metadata: {
        ...(baseContext.metadata ?? {}),
        videoId: getYouTubeVideoId(sourceUrl),
        extractionSource: "mock-fallback"
      }
    };
  }
};

export const extractIngredientsFromContext = async (context: RawRecipeContext): Promise<Ingredient[]> => {
  const hints = readHints(context);
  const hintedIngredients = hints.ingredientHints ?? [];

  if (hintedIngredients.length) {
    return hintedIngredients.map((ingredient, index) => ({
      id: buildId("ingredient", index),
      name: String(ingredient.name ?? "Ingredient"),
      quantity: typeof ingredient.quantity === "string" ? ingredient.quantity : ingredient.quantity == null ? null : String(ingredient.quantity),
      unit: typeof ingredient.unit === "string" ? ingredient.unit : ingredient.unit == null ? null : String(ingredient.unit),
      note: typeof ingredient.note === "string" ? ingredient.note : null,
      optional: Boolean(ingredient.optional),
      inferred: Boolean(ingredient.inferred)
    }));
  }

  const transcript = `${context.caption ?? ""} ${context.transcript ?? ""}`.toLowerCase();
  const ingredients: Ingredient[] = [];

  if (transcript.includes("chicken")) {
    ingredients.push({ id: buildId("ingredient", ingredients.length), name: "Chicken", quantity: null, inferred: true });
  }
  if (transcript.includes("garlic")) {
    ingredients.push({ id: buildId("ingredient", ingredients.length), name: "Garlic", quantity: null, inferred: true });
  }
  if (transcript.includes("cream")) {
    ingredients.push({ id: buildId("ingredient", ingredients.length), name: "Cream", quantity: null, inferred: true });
  }

  return ingredients;
};

export const extractStepsFromContext = async (context: RawRecipeContext): Promise<RecipeStep[]> => {
  const hints = readHints(context);
  const stepHints = hints.stepHints ?? [];

  if (stepHints.length) {
    return stepHints.map((step, index) => ({
      id: buildId("step", index),
      order: index + 1,
      instruction: String(step.instruction ?? "Complete this cooking step."),
      durationMinutes:
        typeof step.durationMinutes === "number"
          ? step.durationMinutes
          : typeof step.duration_minutes === "number"
            ? step.duration_minutes
            : null,
      temperature: typeof step.temperature === "string" ? step.temperature : null,
      inferred: Boolean(step.inferred)
    }));
  }

  return [
    {
      id: "step-1",
      order: 1,
      instruction: "Extracted recipe steps were incomplete, so Cooksy created a draft method.",
      inferred: true
    }
  ];
};

export const extractRecipeMetadata = async (context: RawRecipeContext) => {
  const hints = readHints(context);
  const title = context.title?.trim() || `${context.platform} recipe import`;
  const description = context.caption?.trim() || context.transcript?.slice(0, 160) || "Imported from social cooking content.";
  const servings = hints.servingsHint ?? null;
  const prepTimeMinutes = hints.prepTimeMinutesHint ?? null;
  const cookTimeMinutes = hints.cookTimeMinutesHint ?? null;

  return {
    title,
    description,
    servings,
    prepTimeMinutes,
    cookTimeMinutes,
    totalTimeMinutes:
      typeof prepTimeMinutes === "number" && typeof cookTimeMinutes === "number"
        ? prepTimeMinutes + cookTimeMinutes
        : null,
    sourceCreator: context.creator ?? null,
    sourceTitle: context.title ?? null
  };
};

export const inferMissingRecipeFields = async (
  partialRecipe: Omit<ReconstructionResult, "confidenceScore" | "validationWarnings" | "inferredFields" | "missingFields">,
  context: RawRecipeContext
) => {
  const inferredFields: string[] = [
    ...partialRecipe.ingredients
      .filter((ingredient) => ingredient.inferred)
      .map((ingredient) => `${ingredient.name} inferred from partial source cues`),
    ...partialRecipe.steps
      .filter((step) => step.inferred)
      .map((step) => `Step ${step.order} reconstructed from incomplete source detail`)
  ];
  const missingFields: string[] = [];

  const ingredients = partialRecipe.ingredients.map((ingredient) => {
    if (!ingredient.quantity) {
      const inferredQuantity = ingredient.name.toLowerCase().includes("garlic") ? "4" : null;

      if (!inferredQuantity) {
        missingFields.push(`${ingredient.name} quantity not provided`);
        return ingredient;
      }

      inferredFields.push(`${ingredient.name} quantity inferred`);
      return {
        ...ingredient,
        quantity: inferredQuantity,
        unit: ingredient.unit ?? (ingredient.name.toLowerCase().includes("garlic") ? "cloves" : ingredient.unit),
        inferred: true
      };
    }

    return ingredient;
  });

  const steps = partialRecipe.steps.map((step) => {
    if (!step.temperature && /roast|oven|bake/i.test(step.instruction)) {
      missingFields.push(`Temperature missing for step ${step.order}`);
    }

    return step;
  });

  const servings = partialRecipe.servings ?? (ingredients.length >= 5 ? 4 : 2);
  if (partialRecipe.servings == null) {
    inferredFields.push("Serving size inferred");
  }

  const prepTimeMinutes = partialRecipe.prepTimeMinutes ?? (context.transcript ? 12 : null);
  if (partialRecipe.prepTimeMinutes == null) {
    inferredFields.push("Prep time inferred");
  }

  const cookTimeMinutes =
    partialRecipe.cookTimeMinutes ??
    (steps.some((step) => step.durationMinutes) ? steps.reduce((sum, step) => sum + (step.durationMinutes ?? 0), 0) : null);
  if (partialRecipe.cookTimeMinutes == null) {
    inferredFields.push("Cook time inferred");
  }

  const totalTimeMinutes =
    partialRecipe.totalTimeMinutes ??
    (typeof prepTimeMinutes === "number" && typeof cookTimeMinutes === "number" ? prepTimeMinutes + cookTimeMinutes : null);

  if (!context.transcript && !context.caption) {
    missingFields.push("No transcript or caption available");
  }

  return {
    ...partialRecipe,
    ingredients,
    steps,
    servings,
    prepTimeMinutes,
    cookTimeMinutes,
    totalTimeMinutes,
    inferredFields,
    missingFields
  };
};

export const validateRecipe = (recipe: Omit<ReconstructionResult, "rawExtraction"> & { sourceUrl: string; sourcePlatform: SourcePlatform }) => {
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

  if (!recipe.steps.some((step) => /garlic|cream|stock|pasta|salmon|chicken/i.test(step.instruction))) {
    warnings.push("Steps do not reference many of the detected cooking cues");
  }

  return warnings;
};

export const scoreRecipeConfidence = (
  recipe: Omit<ReconstructionResult, "rawExtraction">,
  context: RawRecipeContext
) => {
  let score = 25;

  if (context.transcript && context.transcript.length > 120) {
    score += 24;
  } else if (context.caption) {
    score += 10;
  }

  if (recipe.sourceTitle) {
    score += 10;
  }

  if (recipe.sourceCreator) {
    score += 6;
  }

  if (recipe.thumbnailUrl) {
    score += 5;
  }

  const explicitQuantityRatio = recipe.ingredients.length
    ? recipe.ingredients.filter((ingredient) => ingredient.quantity).length / recipe.ingredients.length
    : 0;
  score += Math.round(explicitQuantityRatio * 20);

  if (recipe.steps.length >= 3) {
    score += 10;
  }

  score -= Math.min(recipe.inferredFields.length * 4, 20);
  score -= Math.min(recipe.missingFields.length * 5, 20);
  score -= Math.min(recipe.validationWarnings.length * 6, 24);

  return Math.max(0, Math.min(100, score));
};

export const reconstructRecipe = async (context: RawRecipeContext): Promise<ReconstructionResult> => {
  const ingredients = await extractIngredientsFromContext(context);
  const steps = await extractStepsFromContext(context);
  const metadata = await extractRecipeMetadata(context);

  if (ingredients.length < 1 || steps.length < 1) {
    throw new Error("Cooksy could not reconstruct enough recipe detail from this source");
  }

  const thumbnailUrl = getThumbnailFromContext(context);
  const thumbnailSource = (thumbnailUrl ? context.platform : "generated") as ThumbnailSource;
  const thumbnailFallbackStyle = generateFallbackThumbnailStyle(metadata.title, context.platform);

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
      rawExtraction: context
    },
    context
  );

  const validationWarnings = validateRecipe({
    sourceUrl: context.sourceUrl,
    sourcePlatform: context.platform,
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

  const confidenceScore = scoreRecipeConfidence(
    {
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
      validationWarnings
    },
    context
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
    confidenceScore,
    inferredFields: inferred.inferredFields,
    missingFields: inferred.missingFields,
    validationWarnings,
    rawExtraction: context
  };
};

const combineIngredientQuantity = (ingredient: Ingredient) =>
  [ingredient.quantity, ingredient.unit].filter(Boolean).join(" ").trim() || ingredient.note || "To taste";

const confidenceLevel = (score: number): PersistedRecipe["confidence"] =>
  score >= 85 ? "high" : score >= 60 ? "medium" : "low";

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
