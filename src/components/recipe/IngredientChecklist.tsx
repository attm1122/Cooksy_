import { Check } from "lucide-react-native";
import { Pressable, Text, View } from "react-native";

import type { RecipeIngredient } from "@/types/recipe";

type IngredientChecklistProps = {
  ingredients: RecipeIngredient[];
};

export const IngredientChecklist = ({ ingredients }: IngredientChecklistProps) => (
  <View className="mt-4" style={{ gap: 12 }}>
    {ingredients.map((ingredient) => (
      <Pressable
        key={ingredient.id}
        className="flex-row items-center rounded-[20px] border border-line bg-white px-4 py-3"
        style={{ gap: 12 }}
      >
        <View className="h-6 w-6 items-center justify-center rounded-full border border-line bg-cream">
          {ingredient.checked ? <Check size={14} color="#111111" /> : null}
        </View>
        <View className="flex-1">
          <Text className="text-[15px] font-semibold text-soft-ink">{ingredient.name}</Text>
          <Text className="text-[13px] text-muted">{ingredient.quantity}</Text>
        </View>
      </Pressable>
    ))}
  </View>
);
