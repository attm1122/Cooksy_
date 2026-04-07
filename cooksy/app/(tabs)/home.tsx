import { zodResolver } from "@hookform/resolvers/zod";
import { Link, router } from "expo-router";
import {
  AlertCircle,
  BookmarkPlus,
  ChevronDown,
  ChevronUp,
  Clock3,
  ClipboardPaste,
  LoaderCircle,
  ShieldAlert,
  ShieldCheck,
  ShieldQuestion,
  Sparkles,
} from "lucide-react-native";
import { useCallback, useEffect, useRef, useState } from "react";
import { Controller, useForm } from "react-hook-form";
import { Platform, Pressable, Text, TextInput, View } from "react-native";

import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { EmptyState } from "@/components/common/EmptyState";
import { PlatformBadge } from "@/components/common/PlatformBadge";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { RecipeReadyHandoff } from "@/components/recipe/RecipeReadyHandoff";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { useBeginRecipeImport, useCompleteImportJob, useRetryRecipeImport } from "@/hooks/use-recipes";
import { captureError } from "@/lib/monitoring";
import { importRecipeSchema, type ImportRecipeFormValues } from "@/lib/schemas";
import { canUpload } from "@/lib/subscription";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { formatMinutes } from "@/utils/time";
import type { RecipeConfidenceLevel } from "@/types/recipe";

const FREE_MONTHLY_LIMIT = 5;

const confidenceColors: Record<RecipeConfidenceLevel, { bg: string; icon: typeof ShieldCheck; color: string; label: string }> = {
  high: { bg: "#EEF9F2", icon: ShieldCheck, color: "#1D8F5F", label: "High" },
  medium: { bg: "#FFF6CC", icon: ShieldQuestion, color: "#7A5B00", label: "Review" },
  low: { bg: "#FFF1EE", icon: ShieldAlert, color: "#8F4A1D", label: "Check" },
};

async function getClipboardText(): Promise<string | null> {
  if (Platform.OS === "web") {
    try {
      return await navigator.clipboard.readText();
    } catch {
      return null;
    }
  }
  try {
    const clipboard = await import("expo-clipboard");
    return await clipboard.getStringAsync();
  } catch {
    return null;
  }
}

export default function HomeScreen() {
  const recipes = useCooksyStore((state) => state.recipes);
  const recipesHydrationError = useCooksyStore((state) => state.recipesHydrationError);
  const setSelectedRecipe = useCooksyStore((state) => state.setSelectedRecipe);
  const lastCompletedRecipeId = useCooksyStore((state) => state.lastCompletedRecipeId);
  const setLastCompletedRecipeId = useCooksyStore((state) => state.setLastCompletedRecipeId);
  const saveRecipe = useCooksyStore((state) => state.saveRecipe);
  const mergeRecipes = useCooksyStore((state) => state.mergeRecipes);
  const patchRecipe = useCooksyStore((state) => state.patchRecipe);
  const removeRecipe = useCooksyStore((state) => state.removeRecipe);
  const beginImportMutation = useBeginRecipeImport();
  const completeImportMutation = useCompleteImportJob();
  const retryImportMutation = useRetryRecipeImport();

  const hasRecipes = recipes.length > 0;
  const [importExpanded, setImportExpanded] = useState(!hasRecipes);
  const [quota, setQuota] = useState<{ allowed: boolean; remaining: number } | null>(null);
  const inputRef = useRef<TextInput>(null);

  const {
    control,
    handleSubmit,
    setValue,
    setError,
    formState: { errors },
  } = useForm<ImportRecipeFormValues>({
    resolver: zodResolver(importRecipeSchema),
    defaultValues: { sourceUrl: "" },
  });

  useEffect(() => {
    void canUpload().then(setQuota).catch(() => null);
  }, []);

  useEffect(() => {
    if (!hasRecipes) setImportExpanded(true);
  }, [hasRecipes]);

  const handlePaste = useCallback(async () => {
    const text = await getClipboardText();
    if (text) setValue("sourceUrl", text.trim(), { shouldValidate: true });
    inputRef.current?.focus();
  }, [setValue]);

  const completedRecipe = recipes.find((item) => item.id === lastCompletedRecipeId);

  const onSubmit = handleSubmit(async ({ sourceUrl }) => {
    try {
      const { pendingRecipe, job } = await beginImportMutation.mutateAsync(sourceUrl);
      saveRecipe(pendingRecipe);
      setSelectedRecipe(pendingRecipe.id);
      router.push(`/recipe/${pendingRecipe.id}`);

      completeImportMutation.mutate(job.id, {
        onSuccess: (recipe) => {
          mergeRecipes([
            {
              ...recipe,
              importJobId: recipe.importJobId ?? job.id,
              status: "ready",
              processingMessage: undefined,
              isSaved: true,
            },
          ]);
          setLastCompletedRecipeId(recipe.id);
          void canUpload().then(setQuota).catch(() => null);
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
            inferredFields: [],
          });
          captureError(error, { action: "home_import_completion", recipeId: pendingRecipe.id, jobId: job.id });
        },
      });
    } catch (error) {
      setError("sourceUrl", {
        type: "manual",
        message: error instanceof Error ? error.message : "Cooksy could not start this import",
      });
      captureError(error, { action: "home_import_create" });
    }
  });

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
                isSaved: true,
              },
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
              inferredFields: [],
            });
            captureError(error, { action: "retry_import_completion", recipeId: pendingRecipe.id, jobId: job.id });
          },
        });
      },
      onError: (error) => {
        patchRecipe(recipe.id, {
          status: "failed",
          processingMessage: error instanceof Error ? error.message : "Cooksy could not retry this import",
        });
        captureError(error, { action: "retry_import_create", recipeId: recipe.id });
      },
    });
  };

  const importForm = (
    <>
      <Controller
        control={control}
        name="sourceUrl"
        render={({ field: { onChange, value } }) => (
          <View className="relative">
            <TextInput
              ref={inputRef}
              value={value}
              onChangeText={onChange}
              autoCapitalize="none"
              autoCorrect={false}
              placeholder="Paste a social recipe link"
              placeholderTextColor="#8A8478"
              className="rounded-[22px] border border-line bg-cream px-4 py-4 text-[15px] text-soft-ink"
              style={{ paddingRight: 52 }}
            />
            <Pressable
              onPress={handlePaste}
              accessibilityLabel="Paste from clipboard"
              style={{
                position: "absolute",
                right: 14,
                top: 0,
                bottom: 0,
                justifyContent: "center",
                paddingHorizontal: 4,
              }}
            >
              <ClipboardPaste size={18} color="#706B61" />
            </Pressable>
          </View>
        )}
      />
      {errors.sourceUrl ? <Text className="mt-2 text-[13px] text-danger">{errors.sourceUrl.message}</Text> : null}

      <View className="mt-4 flex-row flex-wrap" style={{ gap: 8 }}>
        <PlatformBadge platform="youtube" />
        <PlatformBadge platform="tiktok" />
        <PlatformBadge platform="instagram" />
      </View>

      <View className="mt-5">
        <PrimaryButton onPress={onSubmit} loading={beginImportMutation.isPending}>
          <View className="flex-row items-center" style={{ gap: 8 }}>
            <BookmarkPlus size={16} color="#111111" />
            <Text className="text-[15px] font-semibold text-ink">Save Recipe</Text>
          </View>
        </PrimaryButton>
      </View>
      <Text className="mt-3 text-[13px] text-muted">
        Saved recipes process in the background so you can move on immediately.
      </Text>
    </>
  );

  return (
    <ScreenContainer>
      {hasRecipes ? (
        <>
          <View className="mb-5 flex-row items-center justify-between">
            <View>
              <Text className="text-[28px] font-bold text-ink">Your kitchen</Text>
              {quota && quota.remaining !== -1 ? (
                <View className="mt-1 flex-row items-center" style={{ gap: 6 }}>
                  <View
                    className="h-2 w-2 rounded-full"
                    style={{ backgroundColor: quota.remaining > 1 ? "#1D8F5F" : quota.remaining === 1 ? "#7A5B00" : "#8F4A1D" }}
                  />
                  <Text className="text-[13px] text-muted">
                    {quota.remaining > 0
                      ? `${quota.remaining} of ${FREE_MONTHLY_LIMIT} imports remaining`
                      : "Import limit reached — upgrade for unlimited"}
                  </Text>
                </View>
              ) : null}
            </View>

            <Pressable
              onPress={() => {
                setImportExpanded((v) => !v);
                if (!importExpanded) setTimeout(() => inputRef.current?.focus(), 150);
              }}
              className="flex-row items-center rounded-full border border-line bg-white px-4 py-2"
              style={{ gap: 6 }}
            >
              <BookmarkPlus size={15} color="#111111" />
              <Text className="text-[13px] font-semibold text-soft-ink">Import</Text>
              {importExpanded ? <ChevronUp size={13} color="#706B61" /> : <ChevronDown size={13} color="#706B61" />}
            </Pressable>
          </View>

          {importExpanded ? (
            <CooksyCard className="mb-5">
              {importForm}
            </CooksyCard>
          ) : null}
        </>
      ) : (
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
          {importForm}
        </CooksyCard>
      )}

      {completedRecipe ? (
        <RecipeReadyHandoff recipe={completedRecipe} onDismiss={() => setLastCompletedRecipeId(undefined)} />
      ) : null}

      {hasRecipes ? (
        <>
          <View className="mb-3 flex-row items-center justify-between">
            <Text className="text-[20px] font-bold text-ink">Recently saved</Text>
            <Link href="/recipes" asChild>
              <Text className="text-[14px] font-semibold text-soft-ink">View all</Text>
            </Link>
          </View>

          <View style={{ gap: 14 }}>
            {recipes.slice(0, 5).map((recipe) => {
              const conf = recipe.status === "ready" ? confidenceColors[recipe.confidence] : null;
              const ConfIcon = conf?.icon;

              return (
                <CooksyCard key={recipe.id} className="p-4">
                  <View style={{ gap: 12 }}>
                    <RecipeThumbnail recipe={recipe} timeLabel={formatMinutes(recipe.totalTimeMinutes)} />
                    <View>
                      <Text className="mb-1 text-[18px] font-bold text-ink">{recipe.title}</Text>
                      <Text className="mb-3 text-[13px] text-muted" numberOfLines={2}>
                        {recipe.status === "processing"
                          ? "Saved to your library — generating in the background."
                          : recipe.status === "failed"
                            ? recipe.processingMessage ?? "Cooksy hit a snag finishing this recipe."
                            : recipe.heroNote}
                      </Text>

                      <View className="flex-row items-center justify-between">
                        <View className="flex-row flex-wrap items-center" style={{ gap: 7 }}>
                          <PlatformBadge platform={recipe.source.platform} />

                          {recipe.status === "ready" && recipe.totalTimeMinutes > 0 ? (
                            <View className="flex-row items-center rounded-full border border-line bg-surface-alt px-2.5 py-1" style={{ gap: 4 }}>
                              <Clock3 size={11} color="#706B61" />
                              <Text className="text-[11px] font-semibold text-muted">{formatMinutes(recipe.totalTimeMinutes)}</Text>
                            </View>
                          ) : null}

                          {conf && ConfIcon ? (
                            <View
                              className="flex-row items-center rounded-full px-2.5 py-1"
                              style={{ backgroundColor: conf.bg, gap: 4 }}
                            >
                              <ConfIcon size={11} color={conf.color} />
                              <Text className="text-[11px] font-semibold" style={{ color: conf.color }}>
                                {conf.label}
                              </Text>
                            </View>
                          ) : null}

                          {recipe.status === "processing" ? (
                            <View className="flex-row items-center rounded-full bg-brand-yellow-soft px-2.5 py-1" style={{ gap: 5 }}>
                              <LoaderCircle size={12} color="#111111" />
                              <Text className="text-[11px] font-semibold text-soft-ink">Generating</Text>
                            </View>
                          ) : null}

                          {recipe.status === "failed" ? (
                            <View className="flex-row items-center rounded-full bg-[#FFF1E8] px-2.5 py-1" style={{ gap: 5 }}>
                              <AlertCircle size={12} color="#8F4A1D" />
                              <Text className="text-[11px] font-semibold text-[#8F4A1D]">Retry</Text>
                            </View>
                          ) : null}
                        </View>

                        {recipe.status === "failed" ? (
                          <SecondaryButton fullWidth={false} onPress={() => handleRetry(recipe.id)} loading={retryImportMutation.isPending}>
                            Retry
                          </SecondaryButton>
                        ) : (
                          <Pressable
                            onPress={() => {
                              setSelectedRecipe(recipe.id);
                              router.push(`/recipe/${recipe.id}`);
                            }}
                            className="rounded-full bg-ink px-4 py-2"
                          >
                            <Text className="text-[13px] font-semibold text-white">Open</Text>
                          </Pressable>
                        )}
                      </View>
                    </View>
                  </View>
                </CooksyCard>
              );
            })}
          </View>
        </>
      ) : recipesHydrationError ? (
        <EmptyState
          title="Could not load recent saves"
          description="Cooksy couldn't reach your recipe library right now. Your existing data isn't being replaced with demo content."
        />
      ) : (
        <CooksyCard className="border-dashed border-line bg-surface-alt">
          <View className="items-center py-4">
            <View className="mb-4 h-14 w-14 items-center justify-center rounded-[20px] bg-brand-yellow-soft">
              <Sparkles size={24} color="#111111" />
            </View>
            <Text className="mb-2 text-center text-[20px] font-bold text-ink">Your first recipe is one paste away</Text>
            <Text className="mb-5 max-w-[320px] text-center text-[14px] leading-6 text-muted">
              Copy any TikTok, Instagram, or YouTube link. Tap the paste icon in the field above. Cooksy handles the rest.
            </Text>
            <View className="w-full rounded-[16px] border border-line bg-white p-4" style={{ gap: 8 }}>
              <View className="flex-row items-center" style={{ gap: 10 }}>
                <View className="h-2.5 w-2.5 rounded-full bg-brand-yellow" />
                <Text className="flex-1 text-[14px] text-soft-ink">Title, ingredients, and method extracted</Text>
              </View>
              <View className="flex-row items-center" style={{ gap: 10 }}>
                <View className="h-2.5 w-2.5 rounded-full bg-brand-yellow" />
                <Text className="flex-1 text-[14px] text-soft-ink">Cook time and confidence score added</Text>
              </View>
              <View className="flex-row items-center" style={{ gap: 10 }}>
                <View className="h-2.5 w-2.5 rounded-full bg-brand-yellow" />
                <Text className="flex-1 text-[14px] text-soft-ink">Grocery list ready before you leave the page</Text>
              </View>
            </View>
          </View>
        </CooksyCard>
      )}
    </ScreenContainer>
  );
}
