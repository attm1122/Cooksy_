import { router, useLocalSearchParams } from "expo-router";
import { ArrowLeft, ShoppingBasket } from "lucide-react-native";
import { Text, View } from "react-native";

import { CooksyCard } from "@/components/common/CooksyCard";
import { EmptyState } from "@/components/common/EmptyState";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { TertiaryButton } from "@/components/common/Buttons";
import { IngredientChecklist } from "@/components/recipe/IngredientChecklist";
import { useCooksyStore } from "@/store/use-cooksy-store";

export default function GroceryListScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id));
  const toggleIngredientChecked = useCooksyStore((state) => state.toggleIngredientChecked);

  if (!recipe) {
    return (
      <ScreenContainer>
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

  const checkedCount = recipe.ingredients.filter((ingredient) => ingredient.checked).length;

  return (
    <ScreenContainer>
      <TertiaryButton onPress={() => router.back()} fullWidth={false}>
        <View className="flex-row items-center" style={{ gap: 8 }}>
          <ArrowLeft size={16} color="#262626" />
          <Text>Back to recipe</Text>
        </View>
      </TertiaryButton>
      <View className="mb-5 mt-4 flex-row items-start justify-between" style={{ gap: 14 }}>
        <View className="flex-1">
          <Text className="mb-2 text-[13px] font-semibold uppercase tracking-[1px] text-muted">Grocery list</Text>
          <Text className="text-[30px] font-bold leading-[36px] text-ink">{recipe.title}</Text>
          <Text className="mt-2 text-[15px] leading-6 text-muted">
            One tap from recipe to shopping. Check items off as you go and keep the list focused on what you actually need.
          </Text>
        </View>
        <View className="h-12 w-12 items-center justify-center rounded-full bg-brand-yellow-soft">
          <ShoppingBasket size={20} color="#111111" />
        </View>
      </View>

      <CooksyCard className="mb-4">
        <Text className="text-[18px] font-bold text-ink">
          {checkedCount} of {recipe.ingredients.length} picked up
        </Text>
        <Text className="mt-2 text-[14px] leading-6 text-muted">
          Tap an ingredient to mark it as picked up. Cooksy keeps the list tied directly to the recipe so fixing the recipe fixes the shop.
        </Text>
      </CooksyCard>

      {recipe.ingredients.length ? (
        <CooksyCard>
          <IngredientChecklist
            ingredients={recipe.ingredients}
            onToggleIngredient={(ingredientId) => toggleIngredientChecked(recipe.id, ingredientId)}
          />
        </CooksyCard>
      ) : (
        <EmptyState
          title="No ingredients yet"
          description="The grocery list will appear as soon as Cooksy finishes reconstructing the recipe."
        />
      )}
    </ScreenContainer>
  );
}
