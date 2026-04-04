import { useLocalSearchParams } from "expo-router";
import { ShoppingBasket } from "lucide-react-native";
import { Text, View } from "react-native";

import { CooksyCard } from "@/components/common/CooksyCard";
import { EmptyState } from "@/components/common/EmptyState";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { IngredientChecklist } from "@/components/recipe/IngredientChecklist";
import { useCooksyStore } from "@/store/use-cooksy-store";

export default function GroceryListScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id));
  const toggleIngredientChecked = useCooksyStore((state) => state.toggleIngredientChecked);

  if (!recipe) {
    return null;
  }

  const checkedCount = recipe.ingredients.filter((ingredient) => ingredient.checked).length;

  return (
    <ScreenContainer>
      <View className="mb-5 flex-row items-start justify-between" style={{ gap: 14 }}>
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
