import { useLocalSearchParams } from "expo-router";
import { ChevronLeft, ChevronRight, TimerReset } from "lucide-react-native";
import { Text, View } from "react-native";

import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { useCooksyStore } from "@/store/use-cooksy-store";

export default function CookingModeScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id));
  const stepIndex = useCooksyStore((state) => state.cookingStepIndex);
  const startCooking = useCooksyStore((state) => state.startCooking);
  const nextCookingStep = useCooksyStore((state) => state.nextCookingStep);
  const previousCookingStep = useCooksyStore((state) => state.previousCookingStep);

  if (!recipe) {
    return null;
  }

  const activeStep = recipe.steps[stepIndex];

  return (
    <ScreenContainer scroll={false}>
      <View className="flex-1 justify-between py-6">
        <View>
          <Text className="mb-2 text-[13px] font-semibold uppercase tracking-[1px] text-muted">Cooking mode</Text>
          <Text className="mb-6 text-[32px] font-bold leading-[38px] text-ink">{recipe.title}</Text>

          <View className="rounded-[32px] bg-white px-6 py-8 shadow-card">
            <Text className="mb-3 text-[13px] font-semibold uppercase tracking-[1px] text-muted">
              Step {stepIndex + 1} of {recipe.steps.length}
            </Text>
            <Text className="mb-4 text-[28px] font-bold leading-[34px] text-ink">{activeStep.title}</Text>
            <Text className="text-[18px] leading-8 text-soft-ink">{activeStep.instruction}</Text>
          </View>
        </View>

        <View>
          <SecondaryButton onPress={() => startCooking(recipe.id)} fullWidth>
            <View className="flex-row items-center" style={{ gap: 8 }}>
              <TimerReset size={16} color="#262626" />
              <Text className="text-[15px] font-semibold text-soft-ink">Restart Cooking Mode</Text>
            </View>
          </SecondaryButton>

          <View className="mt-3 flex-row" style={{ gap: 12 }}>
            <SecondaryButton onPress={previousCookingStep} fullWidth>
              <View className="flex-row items-center" style={{ gap: 8 }}>
                <ChevronLeft size={16} color="#262626" />
                <Text className="text-[15px] font-semibold text-soft-ink">Previous</Text>
              </View>
            </SecondaryButton>
            <PrimaryButton onPress={() => nextCookingStep(recipe.steps.length)}>
              <View className="flex-row items-center" style={{ gap: 8 }}>
                <Text className="text-[15px] font-semibold text-ink">Next</Text>
                <ChevronRight size={16} color="#111111" />
              </View>
            </PrimaryButton>
          </View>
        </View>
      </View>
    </ScreenContainer>
  );
}
