import { ChevronDown, ChevronUp, Sparkles } from "lucide-react-native";
import { useState } from "react";
import { Pressable, Text, View } from "react-native";

import { aggregateEvidence, aggregateSourceEvidence } from "@/features/recipes/lib/sourceEvidence";
import type { RawRecipeContext } from "@/types/recipe";
import { colors } from "@/theme/tokens";

const CompactPill = ({ label }: { label: string }) => (
  <View className="rounded-full border border-[#E9E2D1] bg-white px-3 py-1.5">
    <Text className="text-[12px] font-semibold text-soft-ink">{label}</Text>
  </View>
);

const joinReadableList = (items: string[]) => {
  if (items.length <= 1) {
    return items[0] ?? "";
  }

  if (items.length === 2) {
    return `${items[0]} and ${items[1]}`;
  }

  return `${items.slice(0, -1).join(", ")}, and ${items.at(-1)}`;
};

export const SourceEvidenceSummary = ({
  rawExtraction
}: {
  rawExtraction?: RawRecipeContext;
}) => {
  const [expanded, setExpanded] = useState(false);

  if (!rawExtraction) {
    return null;
  }

  const evidence = aggregateSourceEvidence(rawExtraction);
  const aggregated = aggregateEvidence(rawExtraction);
  const signalOrigins = Array.isArray((rawExtraction.metadata as { signalOrigins?: unknown } | null)?.signalOrigins)
    ? ((rawExtraction.metadata as { signalOrigins: unknown[] }).signalOrigins.filter((item): item is string => typeof item === "string"))
    : [];

  const supportSignals = [
    rawExtraction.transcript ? "source text" : rawExtraction.caption ? "caption" : null,
    rawExtraction.ocrText?.length ? "on-screen text" : null,
    rawExtraction.comments?.length ? "comments" : null
  ].filter(Boolean) as string[];

  const summaryLine = supportSignals.length
    ? `Score backed by ${joinReadableList(supportSignals)}.`
    : `Score backed by ${signalOrigins.length || 1} source ${signalOrigins.length === 1 ? "feed" : "feeds"}.`;

  const compactPills = [
    evidence.explicitQuantityMentions ? `${evidence.explicitQuantityMentions} quantities` : null,
    evidence.cueMentions.length ? `${evidence.cueMentions.length} cooking cues` : null,
    aggregated.ingredients.length ? `${aggregated.ingredients.length} ingredient signals` : null,
    signalOrigins.length ? `${signalOrigins.length} source ${signalOrigins.length === 1 ? "feed" : "feeds"}` : null
  ].filter(Boolean) as string[];

  const detailRows = [
    rawExtraction.transcript || rawExtraction.caption
      ? rawExtraction.transcript
        ? "Source text captured from the original post."
        : "Caption text contributed to the trust score."
      : null,
    rawExtraction.ocrText?.length ? `${rawExtraction.ocrText.length} on-screen cue${rawExtraction.ocrText.length === 1 ? "" : "s"} detected.` : null,
    rawExtraction.comments?.length
      ? `${rawExtraction.comments.length} comment cue${rawExtraction.comments.length === 1 ? "" : "s"} used to cross-check details.`
      : null,
    signalOrigins.length ? `Source feeds: ${signalOrigins.join(" + ").replace(/-/g, " ")}.` : null
  ].filter(Boolean) as string[];

  if (!compactPills.length && !detailRows.length) {
    return null;
  }

  return (
    <View className="mt-4 rounded-[20px] border border-[#E9E2D1] bg-[#FFFCF3] px-4 py-3" style={{ gap: 10 }}>
      <View className="flex-row items-start" style={{ gap: 12 }}>
        <View className="mt-0.5 h-9 w-9 items-center justify-center rounded-full bg-brand-yellow-soft">
          <Sparkles size={16} color={colors.ink} />
        </View>
        <View className="flex-1">
          <Text className="text-[11px] font-bold uppercase tracking-[0.7px] text-muted">Evidence Behind Score</Text>
          <Text className="mt-1 text-[14px] font-semibold leading-5 text-ink">{summaryLine}</Text>
        </View>
        {detailRows.length ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={expanded ? "Hide evidence details" : "Show evidence details"}
            className="h-8 w-8 items-center justify-center rounded-full bg-white"
            onPress={() => setExpanded((value) => !value)}
          >
            {expanded ? <ChevronUp size={16} color="#262626" /> : <ChevronDown size={16} color="#262626" />}
          </Pressable>
        ) : null}
      </View>

      {compactPills.length ? (
        <View className="flex-row flex-wrap" style={{ gap: 8 }}>
          {compactPills.map((pill) => (
            <CompactPill key={pill} label={pill} />
          ))}
        </View>
      ) : null}

      {expanded ? (
        <View className="rounded-[16px] border border-[#E9E2D1] bg-white px-3 py-3" style={{ gap: 8 }}>
          {detailRows.map((detail) => (
            <Text key={detail} className="text-[13px] leading-5 text-muted">
              {detail}
            </Text>
          ))}
        </View>
      ) : null}
    </View>
  );
};
