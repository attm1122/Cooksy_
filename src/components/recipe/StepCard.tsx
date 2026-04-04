import { Text, View } from "react-native";

import type { RecipeStep } from "@/types/recipe";

export const StepCard = ({ step, index }: { step: RecipeStep; index: number }) => (
  <View className="rounded-[24px] border border-line bg-white p-5">
    <View className="mb-3 flex-row items-center" style={{ gap: 12 }}>
      <View className="h-9 w-9 items-center justify-center rounded-full bg-brand-yellow">
        <Text className="text-[14px] font-bold text-ink">{index + 1}</Text>
      </View>
      <Text className="flex-1 text-[17px] font-bold text-ink">{step.title}</Text>
    </View>
    <Text className="text-[15px] leading-6 text-soft-ink">{step.instruction}</Text>
  </View>
);
