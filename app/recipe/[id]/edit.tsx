import { useLocalSearchParams } from "expo-router";
import { ScrollView, Text } from "react-native";

import { RecipeEditorForm } from "@/components/recipe/RecipeEditorForm";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { useCooksyStore } from "@/store/use-cooksy-store";

export default function EditRecipeScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id));
  const updateRecipe = useCooksyStore((state) => state.updateRecipe);

  if (!recipe) {
    return null;
  }

  return (
    <ScreenContainer scroll={false}>
      <ScrollView contentContainerClassName="pb-10">
        <Text className="mb-4 text-[28px] font-bold text-ink">Edit recipe</Text>
        <RecipeEditorForm recipe={recipe} onSubmit={updateRecipe} />
      </ScrollView>
    </ScreenContainer>
  );
}
