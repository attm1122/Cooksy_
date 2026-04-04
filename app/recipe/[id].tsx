import { Link, useLocalSearchParams } from "expo-router";
import { PencilLine, Play, Save, SquareStack } from "lucide-react-native";
import { Text, View } from "react-native";

import { ConfidenceBanner } from "@/components/common/ConfidenceBanner";
import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { PlatformBadge } from "@/components/common/PlatformBadge";
import { RecipeMetaRow } from "@/components/common/RecipeMetaRow";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { IngredientChecklist } from "@/components/recipe/IngredientChecklist";
import { StepCard } from "@/components/recipe/StepCard";
import { useCooksyStore } from "@/store/use-cooksy-store";

export default function RecipeDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id));

  if (!recipe) {
    return (
      <ScreenContainer>
        <Text className="text-[18px] font-semibold text-soft-ink">Recipe not found.</Text>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer>
      <View className="mb-5">
        <Text className="mb-3 text-[13px] font-semibold uppercase tracking-[1px] text-muted">Recipe detail</Text>
        <Text className="text-[32px] font-bold leading-[38px] text-ink">{recipe.title}</Text>
        <Text className="mt-2 text-[15px] leading-6 text-muted">{recipe.heroNote}</Text>
      </View>

      <CooksyCard className="mb-4 overflow-hidden p-0">
        <View className="h-[220px] items-center justify-center bg-brand-yellow-soft">
          <Text className="text-[16px] font-semibold text-soft-ink">{recipe.imageLabel}</Text>
        </View>
        <View className="p-5">
          <View className="flex-row items-center justify-between">
            <View>
              <Text className="text-[14px] text-muted">From {recipe.source.creator}</Text>
            </View>
            <PlatformBadge platform={recipe.source.platform} />
          </View>
          <RecipeMetaRow
            servings={recipe.servings}
            prepTimeMinutes={recipe.prepTimeMinutes}
            cookTimeMinutes={recipe.cookTimeMinutes}
          />
          <ConfidenceBanner level={recipe.confidence} note={recipe.confidenceNote} />
        </View>
      </CooksyCard>

      <View className="mb-4 flex-row flex-wrap" style={{ gap: 12 }}>
        <PrimaryButton fullWidth={false}>
          <View className="flex-row items-center" style={{ gap: 8 }}>
            <Save size={16} color="#111111" />
            <Text className="text-[15px] font-semibold text-ink">Save Recipe</Text>
          </View>
        </PrimaryButton>
        <SecondaryButton fullWidth={false}>
          <View className="flex-row items-center" style={{ gap: 8 }}>
            <SquareStack size={16} color="#262626" />
            <Text className="text-[15px] font-semibold text-soft-ink">Save to Book</Text>
          </View>
        </SecondaryButton>
        <Link href={`/recipe/${recipe.id}/edit`} asChild>
          <View>
            <SecondaryButton fullWidth={false}>
              <View className="flex-row items-center" style={{ gap: 8 }}>
                <PencilLine size={16} color="#262626" />
                <Text className="text-[15px] font-semibold text-soft-ink">Edit</Text>
              </View>
            </SecondaryButton>
          </View>
        </Link>
        <Link href={`/recipe/${recipe.id}/cook`} asChild>
          <View>
            <SecondaryButton fullWidth={false}>
              <View className="flex-row items-center" style={{ gap: 8 }}>
                <Play size={16} color="#262626" />
                <Text className="text-[15px] font-semibold text-soft-ink">Cooking Mode</Text>
              </View>
            </SecondaryButton>
          </View>
        </Link>
      </View>

      <CooksyCard className="mb-4">
        <Text className="text-[22px] font-bold text-ink">Ingredients</Text>
        <IngredientChecklist ingredients={recipe.ingredients} />
      </CooksyCard>

      <CooksyCard>
        <Text className="mb-4 text-[22px] font-bold text-ink">Method</Text>
        <View style={{ gap: 12 }}>
          {recipe.steps.map((step, index) => (
            <StepCard key={step.id} step={step} index={index} />
          ))}
        </View>
      </CooksyCard>
    </ScreenContainer>
  );
}
