import { useLocalSearchParams } from "expo-router";
import { Text, View } from "react-native";

import { EmptyState } from "@/components/common/EmptyState";
import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { useCooksyStore } from "@/store/use-cooksy-store";

export default function BookDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const book = useCooksyStore((state) => state.books.find((item) => item.id === id));
  const recipes = useCooksyStore((state) => state.recipes);
  const removeRecipeFromBook = useCooksyStore((state) => state.removeRecipeFromBook);

  if (!book) {
    return null;
  }

  const bookRecipes = recipes.filter((recipe) => book.recipeIds.includes(recipe.id));

  return (
    <ScreenContainer>
      <Text className="text-[31px] font-bold text-ink">{book.name}</Text>
      <Text className="mt-2 text-[15px] leading-6 text-muted">{book.description}</Text>

      <View className="mt-5" style={{ gap: 12 }}>
        {bookRecipes.length ? (
          bookRecipes.map((recipe) => (
            <CooksyCard key={recipe.id} className="p-4">
              <Text className="mb-2 text-[18px] font-bold text-ink">{recipe.title}</Text>
              <Text className="mb-3 text-[14px] text-muted">{recipe.description}</Text>
              <Text className="text-[14px] font-semibold text-soft-ink" onPress={() => removeRecipeFromBook(recipe.id, book.id)}>
                Remove from book
              </Text>
            </CooksyCard>
          ))
        ) : (
          <EmptyState title="No recipes in this book yet" description="Saved recipes will show up here once they’re organised into this collection." />
        )}
      </View>
    </ScreenContainer>
  );
}
