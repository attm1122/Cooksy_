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
import { RecipeEditorForm } from "@/components/recipe/RecipeEditorForm";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { StepCard } from "@/components/recipe/StepCard";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { formatMinutes } from "@/utils/time";

export default function RecipeDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id));
  const updateRecipe = useCooksyStore((state) => state.updateRecipe);

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
        <Text className="mt-2 text-[15px] leading-6 text-muted">
          {recipe.status === "processing"
            ? "Saved to your library. Cooksy is still building the recipe in the background."
            : recipe.heroNote}
        </Text>
      </View>

      <CooksyCard className="mb-4 overflow-hidden p-0">
        <RecipeThumbnail
          recipe={recipe}
          size="hero"
          aspectRatio={16 / 10}
          timeLabel={formatMinutes(recipe.totalTimeMinutes)}
          style={{ borderBottomLeftRadius: 0, borderBottomRightRadius: 0 }}
        />
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
          <ConfidenceBanner
            level={recipe.confidence}
            note={recipe.confidenceNote}
            score={recipe.confidenceScore}
            inferredFields={recipe.inferredFields}
            missingFields={recipe.missingFields}
          />
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
        {recipe.status === "ready" ? (
          <>
            <SecondaryButton fullWidth={false}>
              <View className="flex-row items-center" style={{ gap: 8 }}>
                <PencilLine size={16} color="#262626" />
                <Text className="text-[15px] font-semibold text-soft-ink">Quick Edit Below</Text>
              </View>
            </SecondaryButton>
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
          </>
        ) : null}
      </View>

      {recipe.status === "ready" ? (
        <CooksyCard className="mb-4">
          <View className="mb-4 flex-row items-center justify-between">
            <View>
              <Text className="text-[22px] font-bold text-ink">Quick edit</Text>
              <Text className="mt-1 text-[14px] text-muted">Fix ingredients, steps, and quantities instantly.</Text>
            </View>
            <Link href={`/recipe/${recipe.id}/edit`} asChild>
              <View>
                <SecondaryButton fullWidth={false}>Open Full Editor</SecondaryButton>
              </View>
            </Link>
          </View>
          <RecipeEditorForm recipe={recipe} onSubmit={updateRecipe} submitLabel="Save Edits" compact />
        </CooksyCard>
      ) : null}

      <CooksyCard className="mb-4">
        <Text className="text-[22px] font-bold text-ink">Ingredients</Text>
        {recipe.status === "processing" ? (
          <Text className="mt-4 text-[15px] leading-6 text-muted">Ingredients will appear here as soon as the recipe is ready.</Text>
        ) : (
          <IngredientChecklist ingredients={recipe.ingredients} />
        )}
      </CooksyCard>

      <CooksyCard>
        <Text className="mb-4 text-[22px] font-bold text-ink">Method</Text>
        {recipe.status === "processing" ? (
          <Text className="text-[15px] leading-6 text-muted">Cooksy is still structuring the method from the original source.</Text>
        ) : (
          <View style={{ gap: 12 }}>
            {recipe.steps.map((step, index) => (
              <StepCard key={step.id} step={step} index={index} />
            ))}
          </View>
        )}
      </CooksyCard>
    </ScreenContainer>
  );
}
