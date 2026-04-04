import { Link } from "expo-router";
import { Plus } from "lucide-react-native";
import { useState } from "react";
import { Text, TextInput, View } from "react-native";

import { AppHeader } from "@/components/common/AppHeader";
import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { BookCard } from "@/components/recipe/BookCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { useCreateRecipeBook, useRecipeBooks } from "@/hooks/use-recipes";
import { useCooksyStore } from "@/store/use-cooksy-store";

export default function BooksScreen() {
  const { data: books = [] } = useRecipeBooks();
  const saveBook = useCooksyStore((state) => state.saveBook);
  const createBook = useCreateRecipeBook();
  const [creating, setCreating] = useState(false);
  const [bookName, setBookName] = useState("");
  const [bookDescription, setBookDescription] = useState("");

  const handleCreateBook = () => {
    if (!bookName.trim()) {
      return;
    }

    createBook.mutate(
      {
        name: bookName.trim(),
        description: bookDescription.trim() || "A saved collection for recipes you want to revisit.",
        coverTone: "yellow"
      },
      {
        onSuccess: (book) => {
          saveBook(book);
          setBookName("");
          setBookDescription("");
          setCreating(false);
        }
      }
    );
  };

  return (
    <ScreenContainer>
      <AppHeader />
      <View className="mb-5 flex-row items-center justify-between">
        <View>
          <Text className="text-[28px] font-bold text-ink">Recipe books</Text>
          <Text className="mt-1 text-[15px] text-muted">Organise recipes into collections you’ll actually reuse.</Text>
        </View>
        <SecondaryButton fullWidth={false} onPress={() => setCreating((value) => !value)}>
          <View className="flex-row items-center" style={{ gap: 8 }}>
            <Plus size={16} color="#262626" />
            <Text className="text-[15px] font-semibold text-soft-ink">Create</Text>
          </View>
        </SecondaryButton>
      </View>

      {creating ? (
        <CooksyCard className="mb-5">
          <Text className="mb-3 text-[20px] font-bold text-ink">Create a recipe book</Text>
          <View style={{ gap: 12 }}>
            <TextInput
              value={bookName}
              onChangeText={setBookName}
              placeholder="Book name"
              placeholderTextColor="#8A8478"
              className="rounded-[22px] border border-line bg-cream px-4 py-4 text-[15px] text-soft-ink"
            />
            <TextInput
              value={bookDescription}
              onChangeText={setBookDescription}
              placeholder="What belongs here?"
              placeholderTextColor="#8A8478"
              className="rounded-[22px] border border-line bg-cream px-4 py-4 text-[15px] text-soft-ink"
            />
            <PrimaryButton onPress={handleCreateBook} loading={createBook.isPending}>
              Save Book
            </PrimaryButton>
          </View>
        </CooksyCard>
      ) : null}

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
