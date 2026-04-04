import { useLocalSearchParams } from "expo-router";
import { Text, View } from "react-native";

import { EmptyState } from "@/components/common/EmptyState";
import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { useRemoveRecipeFromBook } from "@/hooks/use-recipes";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { formatMinutes } from "@/utils/time";

export default function BookDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const book = useCooksyStore((state) => state.books.find((item) => item.id === id));
  const recipes = useCooksyStore((state) => state.recipes);
  const removeRecipeFromBook = useCooksyStore((state) => state.removeRecipeFromBook);
  const removeMutation = useRemoveRecipeFromBook();

  if (!book) {
    return null;
  }

  const bookRecipes = recipes.filter((recipe) => book.recipeIds.includes(recipe.id));

  const handleRemove = (recipeId: string) => {
    removeRecipeFromBook(recipeId, book.id);
    removeMutation.mutate({ recipeId, bookId: book.id });
  };

  return (
    <ScreenContainer>
      <Text className="text-[31px] font-bold text-ink">{book.name}</Text>
      <Text className="mt-2 text-[15px] leading-6 text-muted">{book.description}</Text>

      <View className="mt-5" style={{ gap: 12 }}>
        {bookRecipes.length ? (
          bookRecipes.map((recipe) => (
            <CooksyCard key={recipe.id} className="p-4">
              <View style={{ gap: 14 }}>
                <RecipeThumbnail recipe={recipe} size="compact" timeLabel={formatMinutes(recipe.totalTimeMinutes)} />
                <Text className="mb-2 text-[18px] font-bold text-ink">{recipe.title}</Text>
                <Text className="mb-3 text-[14px] text-muted">
                  {recipe.status === "processing" ? "Generating recipe..." : recipe.description}
                </Text>
              </View>
              <Text className="text-[14px] font-semibold text-soft-ink" onPress={() => handleRemove(recipe.id)}>
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
