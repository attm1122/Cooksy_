import type { ReactNode } from "react";
import { FileText, MessageSquareText, ScanText, Sparkles } from "lucide-react-native";
import { Text, View } from "react-native";

import { aggregateSourceEvidence } from "@/features/recipes/lib/sourceEvidence";
import type { RawRecipeContext } from "@/types/recipe";
import { colors } from "@/theme/tokens";

const EvidencePill = ({
  label,
  value
}: {
  label: string;
  value: string;
}) => (
  <View className="rounded-full border border-[#E9E2D1] bg-white px-3 py-2">
    <Text className="text-[11px] font-semibold uppercase tracking-[0.6px] text-muted">{label}</Text>
    <Text className="mt-1 text-[13px] font-semibold text-ink">{value}</Text>
  </View>
);

const EvidenceRow = ({
  icon,
  title,
  detail
}: {
  icon: ReactNode;
  title: string;
  detail: string;
}) => (
  <View className="flex-row items-start" style={{ gap: 10 }}>
    <View className="mt-0.5 h-8 w-8 items-center justify-center rounded-full bg-brand-yellow-soft">{icon}</View>
    <View className="flex-1">
      <Text className="text-[14px] font-semibold text-ink">{title}</Text>
      <Text className="mt-1 text-[13px] leading-5 text-muted">{detail}</Text>
    </View>
  </View>
);

export const SourceEvidenceSummary = ({
  rawExtraction
}: {
  rawExtraction?: RawRecipeContext;
}) => {
  if (!rawExtraction) {
    return null;
  }

  const evidence = aggregateSourceEvidence(rawExtraction);
  const signalOrigins = Array.isArray((rawExtraction.metadata as { signalOrigins?: unknown } | null)?.signalOrigins)
    ? ((rawExtraction.metadata as { signalOrigins: unknown[] }).signalOrigins.filter((item): item is string => typeof item === "string"))
    : [];

  const evidenceRows = [
    rawExtraction.transcript || rawExtraction.caption
      ? {
          key: "source-text",
          icon: <FileText size={16} color={colors.ink} />,
          title: rawExtraction.transcript ? "Source text captured" : "Caption captured",
          detail: rawExtraction.transcript
            ? "Cooksy found spoken or written source text to guide ingredients and steps."
            : "Cooksy used the post description to reconstruct the recipe."
        }
      : null,
    rawExtraction.ocrText?.length
      ? {
          key: "ocr",
          icon: <ScanText size={16} color={colors.ink} />,
          title: "On-screen text used",
          detail: `Detected ${rawExtraction.ocrText.length} on-screen cue${rawExtraction.ocrText.length === 1 ? "" : "s"} from the original post.`
        }
      : null,
    rawExtraction.comments?.length
      ? {
          key: "comments",
          icon: <MessageSquareText size={16} color={colors.ink} />,
          title: "Community clues considered",
          detail: `Cooksy picked up ${rawExtraction.comments.length} comment cue${rawExtraction.comments.length === 1 ? "" : "s"} to cross-check missing details.`
        }
      : null,
    signalOrigins.length
      ? {
          key: "signals",
          icon: <Sparkles size={16} color={colors.ink} />,
          title: "Signal sources",
          detail: signalOrigins.join(" + ").replace(/-/g, " ")
        }
      : null
  ].filter(Boolean) as {
    key: string;
    icon: ReactNode;
    title: string;
    detail: string;
  }[];

  if (!evidenceRows.length) {
    return null;
  }

  return (
    <View className="mt-4 rounded-[22px] border border-[#E9E2D1] bg-[#FFFCF3] p-4" style={{ gap: 14 }}>
      <View>
        <Text className="text-[13px] font-bold uppercase tracking-[0.8px] text-muted">Why Cooksy trusts this</Text>
        <Text className="mt-2 text-[16px] font-semibold leading-6 text-ink">
          Cooksy built this recipe from the original post, then checked how much usable evidence was actually available.
        </Text>
      </View>

      <View className="flex-row flex-wrap" style={{ gap: 8 }}>
        <EvidencePill label="Quantity mentions" value={String(evidence.explicitQuantityMentions)} />
        <EvidencePill label="Cooking cues" value={String(evidence.cueMentions.length)} />
        <EvidencePill label="Signal sources" value={String(evidence.signalOriginCount || 1)} />
      </View>

      <View style={{ gap: 12 }}>
        {evidenceRows.map((row) => (
          <EvidenceRow key={row.key} icon={row.icon} title={row.title} detail={row.detail} />
        ))}
      </View>
    </View>
  );
};
