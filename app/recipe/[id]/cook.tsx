import { router, useLocalSearchParams } from "expo-router";
import { ArrowLeft, ChevronLeft, ChevronRight, TimerReset, X } from "lucide-react-native";
import { Text, View } from "react-native";

import { PrimaryButton, SecondaryButton, TertiaryButton } from "@/components/common/Buttons";
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
    return (
      <ScreenContainer scroll={false}>
        <View className="flex-1 items-center justify-center">
          <Text className="text-[18px] text-muted">Recipe not found</Text>
          <TertiaryButton onPress={() => router.back()}>
            <View className="flex-row items-center" style={{ gap: 8 }}>
              <ArrowLeft size={16} color="#262626" />
              <Text>Go Back</Text>
            </View>
          </TertiaryButton>
        </View>
      </ScreenContainer>
    );
  }

  if (!recipe.steps.length) {
    return (
      <ScreenContainer scroll={false}>
        <View className="flex-1 items-center justify-center">
          <Text className="text-[22px] font-bold text-ink">Cooking mode will unlock when the recipe is ready.</Text>
        </View>
      </ScreenContainer>
    );
  }

  const activeStep = recipe.steps[stepIndex];
  const progressRatio = recipe.steps.length ? (stepIndex + 1) / recipe.steps.length : 0;

  return (
    <ScreenContainer scroll={false}>
      <View className="flex-1 justify-between bg-soft-ink py-6">
        <View>
          <View className="mb-4 flex-row items-center justify-between">
            <Text className="text-[13px] font-semibold uppercase tracking-[1px] text-[#DCCFAF]">Cooking mode</Text>
            <TertiaryButton onPress={() => router.back()} fullWidth={false}>
              <View className="h-8 w-8 items-center justify-center rounded-full bg-white/10">
                <X size={18} color="#E8DDBE" />
              </View>
            </TertiaryButton>
          </View>
          <Text className="mb-2 text-[32px] font-bold leading-[38px] text-white">{recipe.title}</Text>
          <Text className="mb-6 text-[15px] leading-6 text-[#E8DDBE]">One step at a time, built for a real kitchen moment.</Text>

          <View className="mb-6 h-2 overflow-hidden rounded-full bg-[#4A3A22]">
            <View className="h-full rounded-full bg-brand-yellow" style={{ width: `${progressRatio * 100}%` }} />
          </View>

          <View className="rounded-[32px] bg-[#FFF8E5] px-6 py-8 shadow-card">
            <Text className="mb-3 text-[13px] font-semibold uppercase tracking-[1px] text-muted">
              Step {stepIndex + 1} of {recipe.steps.length}
            </Text>
            <Text className="mb-5 text-[30px] font-bold leading-[36px] text-ink">{activeStep.title}</Text>
            <Text className="text-[24px] leading-10 text-soft-ink">{activeStep.instruction}</Text>
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

          <View className="mt-3">
            <SecondaryButton fullWidth>
              <View className="flex-row items-center" style={{ gap: 8 }}>
                <TimerReset size={16} color="#262626" />
                <Text className="text-[15px] font-semibold text-soft-ink">Timer Coming Soon</Text>
              </View>
            </SecondaryButton>
          </View>
        </View>
      </View>
    </ScreenContainer>
  );
}
