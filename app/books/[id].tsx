import { router, useLocalSearchParams } from "expo-router";
import { AlertCircle, LoaderCircle } from "lucide-react-native";
import { Alert, Text, View } from "react-native";

import { EmptyState } from "@/components/common/EmptyState";
import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { useRemoveRecipeFromBook } from "@/hooks/use-recipes";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { formatMinutes } from "@/utils/time";
import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { PlatformBadge } from "@/components/common/PlatformBadge";

export default function BookDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const book = useCooksyStore((state) => state.books.find((item) => item.id === id));
  const recipes = useCooksyStore((state) => state.recipes);
  const setSelectedRecipe = useCooksyStore((state) => state.setSelectedRecipe);
  const removeRecipeFromBook = useCooksyStore((state) => state.removeRecipeFromBook);
  const removeMutation = useRemoveRecipeFromBook();

  if (!book) {
    return (
      <ScreenContainer>
        <EmptyState title="Book not found" description="This recipe book doesn't exist or was deleted." />
      </ScreenContainer>
    );
  }

  const handleOpenRecipe = (recipeId: string) => {
    setSelectedRecipe(recipeId);
    router.push(`/recipe/${recipeId}`);
  };

  const bookRecipes = recipes.filter((recipe) => book.recipeIds.includes(recipe.id));

  const handleRemove = (recipeId: string) => {
    removeRecipeFromBook(recipeId, book.id);
    removeMutation.mutate(
      { recipeId, bookId: book.id },
      {
        onError: () => {
          useCooksyStore.getState().addRecipeToBook(recipeId, book.id);
          Alert.alert("Book not updated", "Cooksy couldn't remove this recipe from the book yet.");
        }
      }
    );
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
                  {recipe.status === "processing"
                    ? "Generating recipe..."
                    : recipe.status === "failed"
                      ? recipe.processingMessage ?? "This recipe needs another pass."
                      : recipe.description}
                </Text>
                <View className="mb-3 flex-row flex-wrap items-center" style={{ gap: 8 }}>
                  {recipe.status === "processing" ? (
                    <View className="flex-row items-center rounded-full bg-brand-yellow-soft px-3 py-1" style={{ gap: 6 }}>
                      <LoaderCircle size={14} color="#111111" />
                      <Text className="text-[12px] font-semibold text-soft-ink">Generating</Text>
                    </View>
                  ) : null}
                  {recipe.status === "failed" ? (
                    <View className="flex-row items-center rounded-full bg-[#FFF1E8] px-3 py-1" style={{ gap: 6 }}>
                      <AlertCircle size={14} color="#8F4A1D" />
                      <Text className="text-[12px] font-semibold text-[#8F4A1D]">Import incomplete</Text>
                    </View>
                  ) : null}
                </View>
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
