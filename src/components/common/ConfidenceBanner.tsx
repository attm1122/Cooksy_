import { ChevronDown, ChevronUp, ShieldAlert, ShieldCheck, ShieldQuestion } from "lucide-react-native";
import { useState } from "react";
import { Pressable, Text, View } from "react-native";

import type { RecipeConfidenceLevel } from "@/types/recipe";

const toneClasses: Record<RecipeConfidenceLevel, string> = {
  high: "bg-[#EEF9F2] border-[#D0EDD9]",
  medium: "bg-brand-yellow-soft border-[#F0D96B]",
  low: "bg-[#FFF1EE] border-[#F1D0C8]"
};

export const ConfidenceBanner = ({
  level,
  note,
  score,
  warnings,
  inferredFields,
  missingFields,
  lowConfidenceAreas
}: {
  level: RecipeConfidenceLevel;
  note: string;
  score: number;
  warnings?: string[];
  inferredFields: string[];
  missingFields: string[];
  lowConfidenceAreas?: string[];
}) => {
  const [expanded, setExpanded] = useState(false);
  const Icon = level === "high" ? ShieldCheck : level === "medium" ? ShieldQuestion : ShieldAlert;
  const headline =
    level === "high"
      ? "High confidence"
      : level === "medium"
        ? "May need review"
        : "Check ingredients and steps";

  return (
    <View className={`mt-4 rounded-[22px] border p-4 ${toneClasses[level]}`} style={{ gap: 12 }}>
      <View className="flex-row" style={{ gap: 12 }}>
        <Icon size={18} color="#111111" />
        <View className="flex-1">
          <Text className="mb-1 text-[13px] font-bold uppercase tracking-[0.8px] text-ink">
            {headline} · {score}/100
          </Text>
          <Text className="text-[14px] leading-5 text-soft-ink">{note}</Text>
        </View>
      </View>
      {(inferredFields.length || missingFields.length || warnings?.length || lowConfidenceAreas?.length) ? (
        <>
          <Pressable onPress={() => setExpanded((value) => !value)} className="flex-row items-center justify-between">
            <Text className="text-[14px] font-semibold text-soft-ink">What to review</Text>
            {expanded ? <ChevronUp size={16} color="#262626" /> : <ChevronDown size={16} color="#262626" />}
          </Pressable>
          {expanded ? (
            <View style={{ gap: 8 }}>
              {(warnings ?? []).map((warning) => (
                <Text key={warning} className="text-[14px] text-soft-ink">
                  {warning}
                </Text>
              ))}
              {(lowConfidenceAreas ?? []).map((area) => (
                <Text key={area} className="text-[14px] text-soft-ink">
                  Review: {area}
                </Text>
              ))}
              {inferredFields.map((field) => (
                <Text key={field} className="text-[14px] text-soft-ink">
                  {field}
                </Text>
              ))}
              {missingFields.map((field) => (
                <Text key={field} className="text-[14px] text-muted">
                  {field}
                </Text>
              ))}
            </View>
          ) : null}
        </>
      ) : null}
    </View>
  );
};
