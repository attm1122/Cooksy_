import type {
  AggregatedEvidence,
  CandidateIngredient,
  CandidateMetadata,
  CandidateStep,
  EvidenceSignal,
  IngredientSignal,
  OcrBlock,
  RawRecipeContext,
  RankedTextCandidate,
  SourceEvidence,
  StepSignal,
  TranscriptSegment
} from "@/features/recipes/types";

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

const normalizeText = (value: string | null | undefined) => value?.replace(/\s+/g, " ").trim() ?? "";
const canonicalize = (value: string) => normalizeText(value).toLowerCase();

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

const buildSignalId = (prefix: string, index: number) => `${prefix}-${index + 1}`;

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

const inferActionVerb = (content: string) => {
  const normalized = canonicalize(content);
  return ACTION_VERBS.find((verb) => normalized.includes(verb)) ?? null;
};

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
  const name = normalizeText(rawName)
    .replace(/\b(of|the|a)\b/gi, "")
    .replace(/\s+/g, " ")
    .trim();

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
    id: buildSignalId("segment", index),
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
    id: buildSignalId("ocr", index),
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

  [
    context.title ? toRankedCandidate(context.title, 0.8, "title") : null,
    context.creator ? toRankedCandidate(context.creator, 0.7, "creator") : null
  ]
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
    new Set([context.thumbnailUrl, ...(context.thumbnailCandidates ?? [])].map((value) => normalizeText(value)).filter(Boolean))
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
    const key = canonicalize(signal.name);
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

      const key = canonicalize(parsed.name);
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
    const key = canonicalize(signal.instruction);
    const confidence = Math.max(0.25, Math.min(0.98, signal.weight));
    const existing = candidateMap.get(key);
    const durationMinutes =
      "durationMinutes" in signal && typeof signal.durationMinutes === "number" ? signal.durationMinutes : null;

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
    .filter((signal) => signal.type !== "comment")
    .forEach((signal) => {
      const parsed = extractStepFromText(signal.content, signal.id, signal.weight, signal.source, signal.timestamp);

      if (!parsed) {
        return;
      }

      const key = canonicalize(parsed.instruction);
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

  const ingredients = buildIngredientCandidates(hydrated, normalizedSignals);
  const steps = buildStepCandidates(hydrated, normalizedSignals);
  const metadata = buildMetadataCandidates(hydrated, normalizedSignals);

  return {
    ingredients,
    steps,
    metadata,
    normalizedSignals
  };
};

export const aggregateSourceEvidence = (context: RawRecipeContext): SourceEvidence => {
  const hydrated = hydrateEvidenceContext(context);
  const aggregated = aggregateEvidence(hydrated);
  const transcriptText = normalizeText(hydrated.transcript ?? hydrated.transcriptSegments?.map((segment) => segment.text).join(" "));
  const captionText = normalizeText(hydrated.caption);
  const ocrText = normalizeText(hydrated.ocrBlocks?.map((block) => block.text).join(" ") ?? hydrated.ocrText?.join(" "));
  const commentsText = normalizeText(hydrated.comments?.join(" "));
  const combinedText = [captionText, transcriptText, ocrText, commentsText].filter(Boolean).join(" ").toLowerCase();
  const cueMentions = FOOD_CUES.filter((cue) => combinedText.includes(cue));
  const explicitQuantityMentions = aggregated.ingredients.filter((ingredient) => ingredient.quantity).length;
  const signalOrigins = Array.isArray((hydrated.metadata as { signalOrigins?: unknown } | null)?.signalOrigins)
    ? ((hydrated.metadata as { signalOrigins: unknown[] }).signalOrigins.filter((item): item is string => typeof item === "string"))
    : [];

  return {
    combinedText,
    transcriptText,
    captionText,
    ocrText,
    commentsText,
    explicitQuantityMentions,
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
