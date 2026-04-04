import { zodResolver } from "@hookform/resolvers/zod";
import { Link, router } from "expo-router";
import { Sparkles } from "lucide-react-native";
import { Controller, useForm } from "react-hook-form";
import { Text, TextInput, View } from "react-native";

import { AppHeader } from "@/components/common/AppHeader";
import { PrimaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { PlatformBadge } from "@/components/common/PlatformBadge";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { useRecentRecipes } from "@/hooks/use-recipes";
import { importRecipeSchema, type ImportRecipeFormValues } from "@/lib/schemas";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { formatMinutes } from "@/utils/time";

export default function HomeScreen() {
  const { data: recipes = [] } = useRecentRecipes();
  const setSelectedRecipe = useCooksyStore((state) => state.setSelectedRecipe);
  const {
    control,
    handleSubmit,
    formState: { errors }
  } = useForm<ImportRecipeFormValues>({
    resolver: zodResolver(importRecipeSchema),
    defaultValues: {
      sourceUrl: "https://youtube.com/watch?v=short-form-cooking-demo"
    }
  });

  const onSubmit = handleSubmit(({ sourceUrl }) => {
    router.push({
      pathname: "/processing",
      params: { url: sourceUrl }
    });
  });

  return (
    <ScreenContainer>
      <AppHeader />

      <CooksyCard className="mb-5">
        <View className="mb-5 flex-row items-start justify-between" style={{ gap: 14 }}>
          <View className="flex-1">
            <Text className="mb-2 text-[31px] font-bold leading-[38px] text-ink">
              Turn video cooking links into clean recipes.
            </Text>
            <Text className="text-[15px] leading-6 text-muted">
              Paste a YouTube, TikTok, or Instagram share link and Cooksy builds a recipe you can actually cook from.
            </Text>
          </View>
          <View className="h-12 w-12 items-center justify-center rounded-full bg-brand-yellow-soft">
            <Sparkles size={20} color="#111111" />
          </View>
        </View>

        <Controller
          control={control}
          name="sourceUrl"
          render={({ field: { onChange, value } }) => (
            <TextInput
              value={value}
              onChangeText={onChange}
              autoCapitalize="none"
              autoCorrect={false}
              placeholder="Paste a social recipe link"
              placeholderTextColor="#8A8478"
              className="rounded-[22px] border border-line bg-cream px-4 py-4 text-[15px] text-soft-ink"
            />
          )}
        />
        {errors.sourceUrl ? <Text className="mt-2 text-[13px] text-danger">{errors.sourceUrl.message}</Text> : null}

        <View className="mt-4 flex-row flex-wrap" style={{ gap: 8 }}>
          <PlatformBadge platform="youtube" />
          <PlatformBadge platform="tiktok" />
          <PlatformBadge platform="instagram" />
        </View>

        <View className="mt-5">
          <PrimaryButton onPress={onSubmit}>Generate Recipe</PrimaryButton>
        </View>
      </CooksyCard>

      <View className="mb-3 flex-row items-center justify-between">
        <Text className="text-[20px] font-bold text-ink">Recent recipes</Text>
        <Link href="/recipes" asChild>
          <Text className="text-[14px] font-semibold text-soft-ink">View all</Text>
        </Link>
      </View>

      <View style={{ gap: 14 }}>
        {recipes.map((recipe) => (
          <Link key={recipe.id} href={`/recipe/${recipe.id}`} asChild>
            <CooksyCard className="p-4">
              <View style={{ gap: 14 }}>
                <RecipeThumbnail recipe={recipe} timeLabel={formatMinutes(recipe.totalTimeMinutes)} />
                <View className="flex-row items-center justify-between">
                  <View className="flex-1">
                    <Text className="mb-1 text-[18px] font-bold text-ink">{recipe.title}</Text>
                    <Text className="mb-2 text-[14px] text-muted">{recipe.heroNote}</Text>
                    <PlatformBadge platform={recipe.source.platform} />
                  </View>
                  <PrimaryButton
                    fullWidth={false}
                    onPress={() => {
                      setSelectedRecipe(recipe.id);
                      router.push(`/recipe/${recipe.id}`);
                    }}
                  >
                    Open
                  </PrimaryButton>
                </View>
              </View>
            </CooksyCard>
          </Link>
        ))}
      </View>
    </ScreenContainer>
  );
}
