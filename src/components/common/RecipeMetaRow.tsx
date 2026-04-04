import { Clock3, Soup, Users } from "lucide-react-native";
import { Text, View } from "react-native";

import { formatMinutes } from "@/utils/time";

type RecipeMetaRowProps = {
  servings: number;
  prepTimeMinutes: number;
  cookTimeMinutes: number;
};

const metaItemClassName = "rounded-[20px] border border-line bg-surface-alt px-4 py-3";

export const RecipeMetaRow = ({ servings, prepTimeMinutes, cookTimeMinutes }: RecipeMetaRowProps) => (
  <View className="mt-4 flex-row flex-wrap" style={{ gap: 12 }}>
    <View className={metaItemClassName}>
      <View className="flex-row items-center" style={{ gap: 8 }}>
        <Users size={16} color="#111111" />
        <Text className="text-[14px] font-semibold text-soft-ink">{servings} servings</Text>
      </View>
    </View>
    <View className={metaItemClassName}>
      <View className="flex-row items-center" style={{ gap: 8 }}>
        <Clock3 size={16} color="#111111" />
        <Text className="text-[14px] font-semibold text-soft-ink">{formatMinutes(prepTimeMinutes)} prep</Text>
      </View>
    </View>
    <View className={metaItemClassName}>
      <View className="flex-row items-center" style={{ gap: 8 }}>
        <Soup size={16} color="#111111" />
        <Text className="text-[14px] font-semibold text-soft-ink">{formatMinutes(cookTimeMinutes)} cook</Text>
      </View>
    </View>
  </View>
);
