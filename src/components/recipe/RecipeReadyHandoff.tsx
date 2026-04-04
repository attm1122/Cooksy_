import { Link } from "expo-router";
import { CheckCircle2, Play, ShoppingBasket, X } from "lucide-react-native";
import { Pressable, Text, View } from "react-native";

import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import type { Recipe } from "@/types/recipe";

export const RecipeReadyHandoff = ({
  recipe,
  onDismiss
}: {
  recipe: Recipe;
  onDismiss: () => void;
}) => (
  <CooksyCard className="mb-4 border-[#E7D56A] bg-[#FFF8DB]">
    <View className="flex-row items-start justify-between" style={{ gap: 12 }}>
      <View className="flex-1">
        <View className="flex-row items-center" style={{ gap: 8 }}>
          <CheckCircle2 size={18} color="#111111" />
          <Text className="text-[13px] font-bold uppercase tracking-[0.8px] text-soft-ink">Recipe ready</Text>
        </View>
        <Text className="mt-3 text-[24px] font-bold leading-[30px] text-ink">{recipe.title}</Text>
        <Text className="mt-2 text-[14px] leading-6 text-muted">
          Cooksy finished reconstructing this recipe. You can cook it now, check the grocery list, or review the full detail.
        </Text>
      </View>
      <Pressable onPress={onDismiss} className="h-9 w-9 items-center justify-center rounded-full bg-white/80">
        <X size={16} color="#262626" />
      </Pressable>
    </View>

    <View className="mt-4 flex-row flex-wrap" style={{ gap: 10 }}>
      <Link href={`/recipe/${recipe.id}/cook`} asChild>
        <View>
          <PrimaryButton fullWidth={false}>
            <View className="flex-row items-center" style={{ gap: 8 }}>
              <Play size={16} color="#111111" />
              <Text className="text-[15px] font-semibold text-ink">Start Cooking</Text>
            </View>
          </PrimaryButton>
        </View>
      </Link>
      <Link href={`/recipe/${recipe.id}/grocery`} asChild>
        <View>
          <SecondaryButton fullWidth={false}>
            <View className="flex-row items-center" style={{ gap: 8 }}>
              <ShoppingBasket size={16} color="#262626" />
              <Text className="text-[15px] font-semibold text-soft-ink">Open Grocery List</Text>
            </View>
          </SecondaryButton>
        </View>
      </Link>
      <Link href={`/recipe/${recipe.id}`} asChild>
        <View>
          <SecondaryButton fullWidth={false}>See Recipe</SecondaryButton>
        </View>
      </Link>
    </View>
  </CooksyCard>
);
