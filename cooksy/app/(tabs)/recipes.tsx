import { router } from "expo-router";
import { AlertCircle, Clock3, LoaderCircle, ShieldAlert, ShieldCheck, ShieldQuestion } from "lucide-react-native";
import { useMemo, useState } from "react";
import { Text, View } from "react-native";

import { CooksyCard } from "@/components/common/CooksyCard";
import { PrimaryButton } from "@/components/common/Buttons";
import { EmptyState } from "@/components/common/EmptyState";
import { PlatformBadge } from "@/components/common/PlatformBadge";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { SearchInput } from "@/components/common/SearchInput";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { useCompleteImportJob, useRetryRecipeImport } from "@/hooks/use-recipes";
import { captureError } from "@/lib/monitoring";
import { formatMinutes } from "@/utils/time";
import type { RecipeConfidenceLevel } from "@/types/recipe";

const confidenceColors: Record<RecipeConfidenceLevel, { bg: string; icon: typeof ShieldCheck; color: string; label: string }> = {
  high: { bg: "#EEF9F2", icon: ShieldCheck, color: "#1D8F5F", label: "High confidence" },
  medium: { bg: "#FFF6CC", icon: ShieldQuestion, color: "#7A5B00", label: "Needs review" },
  low: { bg: "#FFF1EE", icon: ShieldAlert, color: "#8F4A1D", label: "Check recipe" },
};

export default function RecipesScreen() {
  const recipes = useCooksyStore((state) => state.recipes);
  const recipesHydrationError = useCooksyStore((state) => state.recipesHydrationError);
  const setSelectedRecipe = useCooksyStore((state) => state.setSelectedRecipe);
  const setLastCompletedRecipeId = useCooksyStore((state) => state.setLastCompletedRecipeId);
  const saveRecipe = useCooksyStore((state) => state.saveRecipe);
  const mergeRecipes = useCooksyStore((state) => state.mergeRecipes);
  const patchRecipe = useCooksyStore((state) => state.patchRecipe);
  const removeRecipe = useCooksyStore((state) => state.removeRecipe);
  const retryImportMutation = useRetryRecipeImport();
  const completeImportMutation = useCompleteImportJob();
  const [query, setQuery] = useState("");

  const handleRetry = (recipeId: string) => {
    const recipe = recipes.find((item) => item.id === recipeId);
    if (!recipe) return;

    retryImportMutation.mutate(recipe, {
      onSuccess: ({ pendingRecipe, job }) => {
        removeRecipe(recipeId);
        saveRecipe(pendingRecipe);
        setSelectedRecipe(pendingRecipe.id);
        router.push(`/recipe/${pendingRecipe.id}`);

        completeImportMutation.mutate(job.id, {
          onSuccess: (nextRecipe) => {
            mergeRecipes([
              {
                ...nextRecipe,
                importJobId: nextRecipe.importJobId ?? job.id,
                status: "ready",
                processingMessage: undefined,
                isSaved: true
              }
            ]);
            setLastCompletedRecipeId(nextRecipe.id);
          },
          onError: (error) => {
            patchRecipe(pendingRecipe.id, {
              status: "failed",
              importJobId: job.id,
              processingMessage: error instanceof Error ? error.message : "Recipe generation failed",
              confidence: "low",
              confidenceScore: 28,
              confidenceNote: "Cooksy could not confidently reconstruct this recipe from the source.",
              missingFields: ["Recipe generation failed"],
              inferredFields: []
            });
            captureError(error, {
              action: "recipes_page_retry_completion",
              recipeId: pendingRecipe.id,
              jobId: job.id
            });
          }
        });
      },
      onError: (error) => {
        patchRecipe(recipe.id, {
          status: "failed",
          processingMessage: error instanceof Error ? error.message : "Cooksy could not retry this import"
        });
        captureError(error, {
          action: "recipes_page_retry_create",
          recipeId: recipe.id
        });
      }
    });
  };

  const filteredRecipes = useMemo(
    () =>
      recipes.filter((recipe) => recipe.title.toLowerCase().includes(query.toLowerCase()) || recipe.tags.join(" ").toLowerCase().includes(query.toLowerCase())),
    [query, recipes]
  );

  return (
    <ScreenContainer>
      <Text className="mb-3 text-[28px] font-bold text-ink">Recipes library</Text>
      <Text className="mb-5 text-[15px] leading-6 text-muted">
        Your saved recipes, imports, and polished versions all live here.
      </Text>

      <View className="mb-5">
        <SearchInput value={query} onChangeText={setQuery} placeholder="Search recipes or tags" />
      </View>

      {filteredRecipes.length ? (
        <View style={{ gap: 14 }}>
          {filteredRecipes.map((recipe) => {
            const conf = recipe.status === "ready" ? confidenceColors[recipe.confidence] : null;
            const ConfIcon = conf?.icon;

            return (
              <CooksyCard key={recipe.id} className="p-4">
                <View style={{ gap: 14 }}>
                  <RecipeThumbnail recipe={recipe} size="compact" timeLabel={formatMinutes(recipe.totalTimeMinutes)} />
                  <View>
                    <Text className="mb-1 text-[18px] font-bold text-ink">{recipe.title}</Text>
                    <Text className="mb-3 text-[14px] text-muted">
                      {recipe.status === "processing" ? "Generating recipe…" : recipe.description}
                    </Text>
                  </View>

                  <View className="flex-row items-center justify-between">
                    <View className="flex-row flex-wrap items-center" style={{ gap: 8 }}>
                      <PlatformBadge platform={recipe.source.platform} />

                      {recipe.status === "ready" && recipe.totalTimeMinutes > 0 ? (
                        <View className="flex-row items-center rounded-full border border-line bg-surface-alt px-3 py-1" style={{ gap: 5 }}>
                          <Clock3 size={12} color="#706B61" />
                          <Text className="text-[12px] font-semibold text-muted">{formatMinutes(recipe.totalTimeMinutes)}</Text>
                        </View>
                      ) : null}

                      {conf && ConfIcon ? (
                        <View
                          className="flex-row items-center rounded-full px-3 py-1"
                          style={{ backgroundColor: conf.bg, gap: 5 }}
                        >
                          <ConfIcon size={12} color={conf.color} />
                          <Text className="text-[12px] font-semibold" style={{ color: conf.color }}>
                            {conf.label}
                          </Text>
                        </View>
                      ) : null}

                      {recipe.status === "processing" ? (
                        <View className="flex-row items-center rounded-full bg-brand-yellow-soft px-3 py-1" style={{ gap: 6 }}>
                          <LoaderCircle size={14} color="#111111" />
                          <Text className="text-[12px] font-semibold text-soft-ink">Generating</Text>
                        </View>
                      ) : null}

                      {recipe.status === "failed" ? (
                        <View className="flex-row items-center rounded-full bg-[#FFF1E8] px-3 py-1" style={{ gap: 6 }}>
                          <AlertCircle size={14} color="#8F4A1D" />
                          <Text className="text-[12px] font-semibold text-[#8F4A1D]">Retry needed</Text>
                        </View>
                      ) : null}
                    </View>

                    {recipe.status === "failed" ? (
                      <PrimaryButton fullWidth={false} onPress={() => handleRetry(recipe.id)} loading={retryImportMutation.isPending}>
                        Try Again
                      </PrimaryButton>
                    ) : recipe.status === "processing" ? (
                      <Text className="text-[13px] font-semibold text-muted">Saved just now</Text>
                    ) : (
                      <PrimaryButton
                        fullWidth={false}
                        onPress={() => {
                          setSelectedRecipe(recipe.id);
                          router.push(`/recipe/${recipe.id}`);
                        }}
                      >
                        Open
                      </PrimaryButton>
                    )}
                  </View>
                </View>
              </CooksyCard>
            );
          })}
        </View>
      ) : recipesHydrationError ? (
        <EmptyState
          title="Could not load your recipes"
          description="Cooksy couldn't reach your saved recipes right now. Check the connection and try again instead of relying on stale or demo data."
        />
      ) : (
        <EmptyState
          title={query ? "No recipes match that search" : "No saved recipes yet"}
          description={
            query
              ? "Try a different recipe name or clear the search to see everything you've saved."
              : "Paste a TikTok, Instagram Reel, or YouTube link and Cooksy will turn it into something you can cook."
          }
        />
      )}
    </ScreenContainer>
  );
}
