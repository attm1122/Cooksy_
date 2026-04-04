import { Text, View } from "react-native";

import type { RecipeBook } from "@/types/recipe";

const toneClassMap = {
  yellow: "bg-brand-yellow-soft",
  cream: "bg-surface-alt",
  ink: "bg-soft-ink"
} as const;

const titleClassMap = {
  yellow: "text-ink",
  cream: "text-ink",
  ink: "text-white"
} as const;

const bodyClassMap = {
  yellow: "text-soft-ink",
  cream: "text-soft-ink",
  ink: "text-[#E8E1D3]"
} as const;

export const BookCard = ({ book }: { book: RecipeBook }) => (
  <View className={`rounded-[26px] p-5 ${toneClassMap[book.coverTone]}`}>
    <Text className={`mb-2 text-[20px] font-bold ${titleClassMap[book.coverTone]}`}>{book.name}</Text>
    <Text className={`mb-5 text-[14px] leading-5 ${bodyClassMap[book.coverTone]}`}>{book.description}</Text>
    <Text className={`text-[13px] font-semibold ${bodyClassMap[book.coverTone]}`}>{book.recipeIds.length} recipes</Text>
  </View>
);
