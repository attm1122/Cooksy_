import { AlertCircle } from "lucide-react-native";
import { Text, View } from "react-native";

import type { RecipeConfidenceLevel } from "@/types/recipe";

const toneClasses: Record<RecipeConfidenceLevel, string> = {
  high: "bg-[#EEF9F2] border-[#D0EDD9]",
  medium: "bg-brand-yellow-soft border-[#F0D96B]",
  low: "bg-[#FFF1EE] border-[#F1D0C8]"
};

export const ConfidenceBanner = ({
  level,
  note
}: {
  level: RecipeConfidenceLevel;
  note: string;
}) => (
  <View className={`mt-4 flex-row rounded-[22px] border p-4 ${toneClasses[level]}`} style={{ gap: 12 }}>
    <AlertCircle size={18} color="#111111" />
    <View className="flex-1">
      <Text className="mb-1 text-[13px] font-bold uppercase tracking-[0.8px] text-ink">
        {level} confidence
      </Text>
      <Text className="text-[14px] leading-5 text-soft-ink">{note}</Text>
    </View>
  </View>
);
