import { zodResolver } from "@hookform/resolvers/zod";
import { Link, router } from "expo-router";
import { BookmarkPlus, Sparkles } from "lucide-react-native";
import { Controller, useForm } from "react-hook-form";
import { Text, TextInput, View } from "react-native";

import { AppHeader } from "@/components/common/AppHeader";
import { PrimaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { PlatformBadge } from "@/components/common/PlatformBadge";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { useImportRecipe } from "@/hooks/use-recipes";
import { importRecipeSchema, type ImportRecipeFormValues } from "@/lib/schemas";
import { createPendingRecipeFromUrl, createPendingRecipeId } from "@/services/import-service";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { formatMinutes } from "@/utils/time";

export default function HomeScreen() {
  const recipes = useCooksyStore((state) => state.recipes);
  const setSelectedRecipe = useCooksyStore((state) => state.setSelectedRecipe);
  const saveRecipe = useCooksyStore((state) => state.saveRecipe);
  const updateRecipe = useCooksyStore((state) => state.updateRecipe);
  const patchRecipe = useCooksyStore((state) => state.patchRecipe);
  const mutation = useImportRecipe();
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

  const onSubmit = handleSubmit(async ({ sourceUrl }) => {
    const recipeId = createPendingRecipeId();
    const pendingRecipe = await createPendingRecipeFromUrl(sourceUrl, recipeId);

    saveRecipe(pendingRecipe);
    setSelectedRecipe(recipeId);
    router.push(`/recipe/${recipeId}`);

    mutation.mutate(sourceUrl, {
      onSuccess: (recipe) => {
        updateRecipe({
          ...recipe,
          id: recipeId,
          status: "ready",
          processingMessage: undefined,
          isSaved: true
        });
      },
      onError: (error) => {
        patchRecipe(recipeId, {
          status: "failed",
          processingMessage: error instanceof Error ? error.message : "Recipe generation failed",
          confidence: "low",
          confidenceScore: 28,
          confidenceNote: "Cooksy could not confidently reconstruct this recipe from the source.",
          missingFields: ["Recipe generation failed"],
          inferredFields: []
        });
      }
    });
  });

  return (
    <ScreenContainer>
      <AppHeader />

      <CooksyCard className="mb-5">
        <View className="mb-6 flex-row items-start justify-between" style={{ gap: 14 }}>
          <View className="flex-1">
            <Text className="mb-2 text-[34px] font-bold leading-[40px] text-ink">
              Save the food you discover and actually cook it later.
            </Text>
            <Text className="max-w-[560px] text-[15px] leading-6 text-muted">
              Drop in a social video link. Cooksy saves it instantly, keeps the original vibe, and turns it into a recipe you can fix and trust.
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
          <PrimaryButton onPress={onSubmit} loading={mutation.isPending}>
            <View className="flex-row items-center" style={{ gap: 8 }}>
              <BookmarkPlus size={16} color="#111111" />
              <Text className="text-[15px] font-semibold text-ink">Save Recipe</Text>
            </View>
          </PrimaryButton>
        </View>
        <Text className="mt-3 text-[13px] text-muted">
          Saved recipes keep processing in the background, so you can move on immediately.
        </Text>
      </CooksyCard>

      <View className="mb-3 flex-row items-center justify-between">
        <Text className="text-[20px] font-bold text-ink">Recently saved</Text>
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
                    <Text className="mb-2 text-[14px] text-muted">
                      {recipe.status === "processing"
                        ? "Saved to your library and still generating."
                        : recipe.heroNote}
                    </Text>
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
