import { router, useLocalSearchParams } from "expo-router";
import { ArrowLeft } from "lucide-react-native";
import { ScrollView, Text, View } from "react-native";

import { RecipeEditorForm } from "@/components/recipe/RecipeEditorForm";
import { useUpdateRecipe } from "@/hooks/use-recipes";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { TertiaryButton, SecondaryButton } from "@/components/common/Buttons";

export default function EditRecipeScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id));
  const updateRecipe = useCooksyStore((state) => state.updateRecipe);
  const updateRecipeMutation = useUpdateRecipe();

  if (!recipe) {
    return (
      <ScreenContainer scroll={false}>
        <View className="flex-1 items-center justify-center">
          <Text className="mb-4 text-[18px] text-muted">Recipe not found</Text>
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

  const handleRecipeUpdate = (nextRecipe: typeof recipe) => {
    updateRecipe(nextRecipe);
    updateRecipeMutation.mutate(nextRecipe);
  };

  return (
    <ScreenContainer scroll={false} keyboardAvoiding>
      <TertiaryButton onPress={() => router.back()} fullWidth={false}>
        <View className="flex-row items-center" style={{ gap: 8 }}>
          <ArrowLeft size={16} color="#262626" />
          <Text>Cancel</Text>
        </View>
      </TertiaryButton>
      <ScrollView contentContainerClassName="pb-10">
        <Text className="mb-2 mt-4 text-[28px] font-bold text-ink">Fix recipe</Text>
        <Text className="mb-4 text-[15px] leading-6 text-muted">
          Correct the parts Cooksy inferred, tighten the instructions, and make this version the one you actually cook from.
        </Text>
        <RecipeEditorForm recipe={recipe} onSubmit={handleRecipeUpdate} />
        <View className="mt-4">
          <SecondaryButton onPress={() => router.back()}>
            Cancel
          </SecondaryButton>
        </View>
      </ScrollView>
    </ScreenContainer>
  );
}
