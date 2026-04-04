import { useLocalSearchParams } from "expo-router";
import { ScrollView, Text } from "react-native";

import { RecipeEditorForm } from "@/components/recipe/RecipeEditorForm";
import { useUpdateRecipe } from "@/hooks/use-recipes";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { useCooksyStore } from "@/store/use-cooksy-store";

export default function EditRecipeScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id));
  const updateRecipe = useCooksyStore((state) => state.updateRecipe);
  const updateRecipeMutation = useUpdateRecipe();

  if (!recipe) {
    return null;
  }

  const handleRecipeUpdate = (nextRecipe: typeof recipe) => {
    updateRecipe(nextRecipe);
    updateRecipeMutation.mutate(nextRecipe);
  };

  return (
    <ScreenContainer scroll={false}>
      <ScrollView contentContainerClassName="pb-10">
        <Text className="mb-2 text-[28px] font-bold text-ink">Fix recipe</Text>
        <Text className="mb-4 text-[15px] leading-6 text-muted">
          Correct the parts Cooksy inferred, tighten the instructions, and make this version the one you actually cook from.
        </Text>
        <RecipeEditorForm recipe={recipe} onSubmit={handleRecipeUpdate} />
      </ScrollView>
    </ScreenContainer>
  );
}
