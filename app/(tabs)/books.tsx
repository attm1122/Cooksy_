import { Link } from "expo-router";
import { Plus } from "lucide-react-native";
import { Text, View } from "react-native";

import { AppHeader } from "@/components/common/AppHeader";
import { SecondaryButton } from "@/components/common/Buttons";
import { BookCard } from "@/components/recipe/BookCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { useRecipeBooks } from "@/hooks/use-recipes";

export default function BooksScreen() {
  const { data: books = [] } = useRecipeBooks();

  return (
    <ScreenContainer>
      <AppHeader />
      <View className="mb-5 flex-row items-center justify-between">
        <View>
          <Text className="text-[28px] font-bold text-ink">Recipe books</Text>
          <Text className="mt-1 text-[15px] text-muted">Organise recipes into collections you’ll actually reuse.</Text>
        </View>
        <SecondaryButton fullWidth={false}>
          <View className="flex-row items-center" style={{ gap: 8 }}>
            <Plus size={16} color="#262626" />
            <Text className="text-[15px] font-semibold text-soft-ink">Create</Text>
          </View>
        </SecondaryButton>
      </View>

      <View style={{ gap: 14 }}>
        {books.map((book) => (
          <Link key={book.id} href={`/books/${book.id}`} asChild>
            <View>
              <BookCard book={book} />
            </View>
          </Link>
        ))}
      </View>
    </ScreenContainer>
  );
}
