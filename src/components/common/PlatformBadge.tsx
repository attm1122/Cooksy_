import { Text, View } from "react-native";

import { platformLabelMap } from "@/utils/platform";
import type { SourcePlatform } from "@/types/recipe";

const badgeColorMap: Record<SourcePlatform, string> = {
  youtube: "bg-[#FDE7E4]",
  tiktok: "bg-[#ECECEC]",
  instagram: "bg-[#FBE7EF]"
};

export const PlatformBadge = ({ platform }: { platform: SourcePlatform }) => (
  <View className={`rounded-full px-3 py-1 ${badgeColorMap[platform]}`}>
    <Text className="text-[12px] font-semibold text-soft-ink">{platformLabelMap[platform]}</Text>
  </View>
);
