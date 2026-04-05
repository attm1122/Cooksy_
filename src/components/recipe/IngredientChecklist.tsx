import { Check } from "lucide-react-native";
import { Image, Pressable, Text, View } from "react-native";

import { getIngredientVisual } from "@/components/recipe/ingredient-visuals";
import type { RecipeIngredient } from "@/types/recipe";

type IngredientChecklistProps = {
  ingredients: RecipeIngredient[];
  onToggleIngredient?: (ingredientId: string) => void;
  titleOverride?: string;
};

export const IngredientChecklist = ({ ingredients, onToggleIngredient, titleOverride }: IngredientChecklistProps) => (
  <View className="mt-4" style={{ gap: 12 }}>
    {ingredients.map((ingredient) => {
      const visual = getIngredientVisual(ingredient.name);
      const detailParts = [visual.label, ingredient.quantity].filter(Boolean);

      return (
        <Pressable
          key={ingredient.id}
          className="flex-row items-center rounded-[20px] border border-line bg-white px-4 py-3"
          style={{ gap: 12 }}
          onPress={onToggleIngredient ? () => onToggleIngredient(ingredient.id) : undefined}
        >
          <View
            className={`h-6 w-6 items-center justify-center rounded-full border ${
              ingredient.checked ? "border-brand-yellow bg-brand-yellow" : "border-line bg-cream"
            }`}
          >
            {ingredient.checked ? <Check size={14} color="#111111" /> : null}
          </View>

          {visual.kind === "illustration" ? (
            <View
              className="h-11 w-11 items-center justify-center"
              style={{
                opacity: ingredient.checked ? 0.55 : 1
              }}
            >
              <Image source={visual.asset} style={{ width: 38, height: 38 }} resizeMode="contain" />
            </View>
          ) : (
            <View
              className="h-11 w-11 items-center justify-center rounded-full border"
              style={{
                backgroundColor: visual.backgroundColor,
                borderColor: visual.borderColor,
                opacity: ingredient.checked ? 0.55 : 1
              }}
            >
              <visual.Icon size={20} color={visual.iconColor} />
            </View>
          )}

          <View className="flex-1">
            <Text className={`text-[15px] font-semibold ${ingredient.checked ? "text-muted line-through" : "text-soft-ink"}`}>
              {titleOverride ?? ingredient.name}
            </Text>
            <Text className={`text-[13px] ${ingredient.checked ? "text-muted line-through" : "text-muted"}`}>
              {detailParts.join(" / ")}
            </Text>
          </View>
        </Pressable>
      );
    })}
  </View>
);
