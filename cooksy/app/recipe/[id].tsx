import { Link, router, useLocalSearchParams } from "expo-router";
import { ArrowLeft } from "lucide-react-native";
import { AlertCircle, LoaderCircle, PencilLine, Play, RotateCw, Save, ShoppingBasket, SquareStack } from "lucide-react-native";
import { useEffect, useRef, useState } from "react";
import { Alert, Animated, Easing, Text, View } from "react-native";

import { ConfidenceBanner } from "@/components/common/ConfidenceBanner";
import { PrimaryButton, SecondaryButton, TertiaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { PlatformBadge } from "@/components/common/PlatformBadge";
import { RecipeMetaRow } from "@/components/common/RecipeMetaRow";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { IngredientChecklist } from "@/components/recipe/IngredientChecklist";
import { RecipeEditorForm } from "@/components/recipe/RecipeEditorForm";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { RecipeReadyHandoff } from "@/components/recipe/RecipeReadyHandoff";
import { ReportContentButton } from "@/components/recipe/ReportContentButton";
import { SourceEvidenceSummary } from "@/components/recipe/SourceEvidenceSummary";
import { StepCard } from "@/components/recipe/StepCard";
import { useAddRecipeToBook, useCompleteImportJob, useRetryRecipeImport, useUpdateRecipe } from "@/hooks/use-recipes";
import { captureError } from "@/lib/monitoring";
import { fetchRecipeById } from "@/services/recipe-service";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { formatMinutes } from "@/utils/time";

const IMPORT_STEPS = ["Fetching source", "Extracting recipe", "Structuring ingredients", "Building method"] as const;
const STEP_DURATION_MS = 9000;

function ProcessingProgressCard() {
  const [stepIndex, setStepIndex] = useState(0);
  const barAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const advance = (index: number) => {
      barAnim.setValue(0);
      Animated.timing(barAnim, {
        toValue: 1,
        duration: STEP_DURATION_MS,
        easing: Easing.linear,
        useNativeDriver: false,
      }).start(({ finished }) => {
        if (finished) {
          const next = (index + 1) % IMPORT_STEPS.length;
          setStepIndex(next);
          advance(next);
        }
      });
    };
    advance(0);
    return () => barAnim.stopAnimation();
  }, []);

  const barWidth = barAnim.interpolate({ inputRange: [0, 1], outputRange: ["0%", "100%"] });

  return (
    <CooksyCard className="mb-4">
      <View className="mb-4 flex-row items-center justify-between">
        <Text className="text-[18px] font-bold text-ink">Cooksy is working</Text>
        <View className="flex-row items-center" style={{ gap: 6 }}>
          <LoaderCircle size={14} color="#111111" />
          <Text className="text-[13px] font-semibold text-soft-ink">{IMPORT_STEPS[stepIndex]}</Text>
        </View>
      </View>

      <View className="h-1.5 overflow-hidden rounded-full bg-surface-alt">
        <Animated.View className="h-full rounded-full bg-brand-yellow" style={{ width: barWidth }} />
      </View>

      <View className="mt-4 flex-row flex-wrap" style={{ gap: 8 }}>
        {IMPORT_STEPS.map((step, i) => (
          <View
            key={step}
            className={`rounded-full px-3 py-1 ${i <= stepIndex ? "bg-brand-yellow-soft" : "bg-surface-alt"}`}
          >
            <Text className={`text-[12px] font-semibold ${i <= stepIndex ? "text-soft-ink" : "text-muted"}`}>
              {step}
            </Text>
          </View>
        ))}
      </View>

      <Text className="mt-4 text-[13px] leading-5 text-muted">
        Processing happens in the background. Come back to this page in a minute or two — or it will update automatically.
      </Text>
    </CooksyCard>
  );
}

export default function RecipeDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const recipe = useCooksyStore((state) => state.recipes.find((item) => item.id === id || item.importJobId === id));
  const lastCompletedRecipeId = useCooksyStore((state) => state.lastCompletedRecipeId);
  const setLastCompletedRecipeId = useCooksyStore((state) => state.setLastCompletedRecipeId);
  const updateRecipe = useCooksyStore((state) => state.updateRecipe);
  const saveRecipe = useCooksyStore((state) => state.saveRecipe);
  const mergeRecipes = useCooksyStore((state) => state.mergeRecipes);
  const patchRecipe = useCooksyStore((state) => state.patchRecipe);
  const removeRecipe = useCooksyStore((state) => state.removeRecipe);
  const books = useCooksyStore((state) => state.books);
  const addRecipeToBook = useCooksyStore((state) => state.addRecipeToBook);
  const removeRecipeFromBook = useCooksyStore((state) => state.removeRecipeFromBook);
  const updateRecipeMutation = useUpdateRecipe();
  const addToBookMutation = useAddRecipeToBook();
  const completeImportMutation = useCompleteImportJob();
  const retryImportMutation = useRetryRecipeImport();
  const [recipeLoadState, setRecipeLoadState] = useState<{ recipeId?: string; message?: string }>({});
  const resumedImportJobIdRef = useRef<string | undefined>(undefined);
  const recipeLoadError = recipeLoadState.recipeId === id ? recipeLoadState.message : undefined;
  const isHydratingRecipe = Boolean(id && !recipe && !recipeLoadError);

  useEffect(() => {
    if (!id || recipe) {
      return;
    }

    fetchRecipeById(id)
      .then((fetchedRecipe) => {
        if (!fetchedRecipe) {
          setRecipeLoadState({
            recipeId: id,
            message: "Recipe not found."
          });
          return;
        }

        setRecipeLoadState({
          recipeId: id,
          message: undefined
        });
        mergeRecipes([fetchedRecipe]);
      })
      .catch((error) => {
        setRecipeLoadState({
          recipeId: id,
          message: error instanceof Error ? error.message : "Could not load this recipe."
        });
        captureError(error, {
          action: "hydrate_recipe_detail",
          recipeId: id
        });
      });
  }, [id, mergeRecipes, recipe]);

  useEffect(() => {
    if (
      !recipe ||
      recipe.status !== "processing" ||
      !recipe.importJobId ||
      completeImportMutation.isPending ||
      resumedImportJobIdRef.current === recipe.importJobId
    ) {
      return;
    }

    resumedImportJobIdRef.current = recipe.importJobId;
    completeImportMutation.mutate(recipe.importJobId, {
      onSuccess: (nextRecipe) => {
        mergeRecipes([
          {
            ...nextRecipe,
            importJobId: nextRecipe.importJobId ?? recipe.importJobId,
            status: "ready",
            processingMessage: undefined,
            isSaved: true
          }
        ]);
        setLastCompletedRecipeId(nextRecipe.id);
      },
      onError: (error) => {
        patchRecipe(recipe.id, {
          status: "failed",
          processingMessage: error instanceof Error ? error.message : "Recipe generation failed",
          confidence: "low",
          confidenceScore: 28,
          confidenceNote: "Cooksy could not confidently reconstruct this recipe from the source.",
          missingFields: ["Recipe generation failed"],
          inferredFields: []
        });
        captureError(error, {
          action: "resume_processing_recipe",
          recipeId: recipe.id,
          jobId: recipe.importJobId
        });
      }
    });
  }, [completeImportMutation, mergeRecipes, patchRecipe, recipe, setLastCompletedRecipeId]);

  if (!recipe && isHydratingRecipe) {
    return (
      <ScreenContainer>
        <View className="flex-row items-center" style={{ gap: 10 }}>
          <LoaderCircle size={18} color="#6B655C" />
          <Text className="text-[18px] font-semibold text-soft-ink">Loading recipe…</Text>
        </View>
      </ScreenContainer>
    );
  }

  if (!recipe) {
    return (
      <ScreenContainer>
        <Text className="text-[18px] font-semibold text-soft-ink">{recipeLoadError ?? "Recipe not found."}</Text>
      </ScreenContainer>
    );
  }

  const defaultBook = books[0];
  const handleRecipeUpdate = (nextRecipe: typeof recipe) => {
    const previousRecipe = recipe;
    updateRecipe(nextRecipe);
    updateRecipeMutation.mutate(nextRecipe, {
      onError: (error) => {
        updateRecipe(previousRecipe);
        captureError(error, {
          action: "recipe_edit_persist",
          recipeId: previousRecipe.id
        });
        Alert.alert("Edits not saved", "Cooksy couldn't save those changes yet. Your local edits were rolled back.");
      }
    });
  };

  const handleSaveToBook = () => {
    if (!defaultBook) {
      return;
    }

    addRecipeToBook(recipe.id, defaultBook.id);
    addToBookMutation.mutate(
      { recipeId: recipe.id, bookId: defaultBook.id },
      {
        onError: (error) => {
          removeRecipeFromBook(recipe.id, defaultBook.id);
          captureError(error, {
            action: "recipe_save_to_book",
            recipeId: recipe.id,
            bookId: defaultBook.id
          });
          Alert.alert("Book not updated", "Cooksy couldn't save that book change. Nothing was synced.");
        }
      }
    );
  };

  const handleRetry = () => {
    retryImportMutation.mutate(recipe, {
      onSuccess: ({ pendingRecipe, job }) => {
        removeRecipe(recipe.id);
        saveRecipe(pendingRecipe);
        router.replace(`/recipe/${pendingRecipe.id}`);

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
              action: "recipe_detail_retry_completion",
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
          action: "recipe_detail_retry_create",
          recipeId: recipe.id
        });
      }
    });
  };

  return (
    <ScreenContainer>
      <View className="mb-5">
        <Text className="mb-3 text-[13px] font-semibold uppercase tracking-[1px] text-muted">Recipe detail</Text>
        <Text className="text-[32px] font-bold leading-[38px] text-ink">{recipe.title}</Text>
        <Text className="mt-2 text-[15px] leading-6 text-muted">
          {recipe.status === "processing"
            ? "Saved to your library. Cooksy is still building the recipe in the background."
            : recipe.status === "failed"
              ? recipe.processingMessage ?? "Cooksy could not finish reconstructing this recipe yet."
              : recipe.heroNote}
        </Text>
      </View>

      {recipe.status === "ready" && lastCompletedRecipeId === recipe.id ? (
        <RecipeReadyHandoff recipe={recipe} onDismiss={() => setLastCompletedRecipeId(undefined)} />
      ) : null}

      <CooksyCard className="mb-4 overflow-hidden p-0">
        <RecipeThumbnail
          recipe={recipe}
          size="hero"
          aspectRatio={16 / 10}
          timeLabel={formatMinutes(recipe.totalTimeMinutes)}
          style={{ borderBottomLeftRadius: 0, borderBottomRightRadius: 0 }}
        />
        <View className="p-5">
          <View className="flex-row items-center justify-between">
            <View>
              <Text className="text-[14px] text-muted">From {recipe.source.creator}</Text>
            </View>
            <PlatformBadge platform={recipe.source.platform} />
          </View>
          <RecipeMetaRow
            servings={recipe.servings}
            prepTimeMinutes={recipe.prepTimeMinutes}
            cookTimeMinutes={recipe.cookTimeMinutes}
          />
          <ConfidenceBanner
            level={recipe.confidence}
            note={recipe.confidenceNote}
            score={recipe.confidenceScore}
            warnings={recipe.warnings}
            inferredFields={recipe.inferredFields}
            missingFields={recipe.missingFields}
            lowConfidenceAreas={recipe.editableFields}
          />
          <SourceEvidenceSummary rawExtraction={recipe.rawExtraction} />
        </View>
      </CooksyCard>

      <View className="mb-4 flex-row flex-wrap" style={{ gap: 12 }}>
        <TertiaryButton onPress={() => router.back()}>
          <View className="flex-row items-center" style={{ gap: 8 }}>
            <ArrowLeft size={16} color="#262626" />
            <Text className="text-[15px] font-semibold text-soft-ink">Back</Text>
          </View>
        </TertiaryButton>
        <PrimaryButton fullWidth={false} disabled={recipe.isSaved}>
          <View className="flex-row items-center" style={{ gap: 8 }}>
            <Save size={16} color="#111111" />
            <Text className="text-[15px] font-semibold text-ink">{recipe.isSaved ? "Saved" : "Save Recipe"}</Text>
          </View>
        </PrimaryButton>
        <SecondaryButton fullWidth={false} onPress={handleSaveToBook} disabled={!defaultBook}>
          <View className="flex-row items-center" style={{ gap: 8 }}>
            <SquareStack size={16} color="#262626" />
            <Text className="text-[15px] font-semibold text-soft-ink">
              {defaultBook ? `Save to ${defaultBook.name}` : "Create a Book First"}
            </Text>
          </View>
        </SecondaryButton>
        {recipe.status === "ready" ? (
          <>
            <Link href={`/recipe/${recipe.id}/grocery`} asChild>
              <View>
                <PrimaryButton fullWidth={false}>
                  <View className="flex-row items-center" style={{ gap: 8 }}>
                    <ShoppingBasket size={16} color="#111111" />
                    <Text className="text-[15px] font-semibold text-ink">Grocery List</Text>
                  </View>
                </PrimaryButton>
              </View>
            </Link>
            <SecondaryButton fullWidth={false}>
              <View className="flex-row items-center" style={{ gap: 8 }}>
                <PencilLine size={16} color="#262626" />
                <Text className="text-[15px] font-semibold text-soft-ink">Fix Recipe Below</Text>
              </View>
            </SecondaryButton>
            <Link href={`/recipe/${recipe.id}/cook`} asChild>
              <View>
                <SecondaryButton fullWidth={false}>
                  <View className="flex-row items-center" style={{ gap: 8 }}>
                    <Play size={16} color="#262626" />
                    <Text className="text-[15px] font-semibold text-soft-ink">Cooking Mode</Text>
                  </View>
                </SecondaryButton>
              </View>
            </Link>
          </>
        ) : null}
        {recipe.status === "processing" ? (
          <SecondaryButton fullWidth={false} disabled>
            <View className="flex-row items-center" style={{ gap: 8 }}>
              <LoaderCircle size={16} color="#262626" />
              <Text className="text-[15px] font-semibold text-soft-ink">Generating in background</Text>
            </View>
          </SecondaryButton>
        ) : null}
        {recipe.status === "failed" ? (
          <PrimaryButton fullWidth={false} onPress={handleRetry} loading={retryImportMutation.isPending}>
            <View className="flex-row items-center" style={{ gap: 8 }}>
              <RotateCw size={16} color="#111111" />
              <Text className="text-[15px] font-semibold text-ink">Retry Import</Text>
            </View>
          </PrimaryButton>
        ) : null}
      </View>

      {recipe.status === "processing" ? <ProcessingProgressCard /> : null}

      {recipe.status === "failed" ? (
        <CooksyCard className="mb-4">
          <View className="flex-row items-start" style={{ gap: 12 }}>
            <View className="mt-1 h-9 w-9 items-center justify-center rounded-full bg-[#FFF1E8]">
              <AlertCircle size={18} color="#8F4A1D" />
            </View>
            <View className="flex-1">
              <Text className="text-[18px] font-bold text-ink">Import needs another pass</Text>
              <Text className="mt-2 text-[14px] leading-6 text-muted">
                The saved link is still in your library. Retry the import to fetch a fresh job while keeping the original source and cover.
              </Text>
            </View>
          </View>
        </CooksyCard>
      ) : null}

      {recipe.status === "ready" ? (
        <CooksyCard className="mb-4">
          <View className="mb-4 flex-row items-center justify-between">
            <View>
              <Text className="text-[22px] font-bold text-ink">Fix recipe</Text>
              <Text className="mt-1 text-[14px] text-muted">Correct ingredients, steps, and time estimates in one pass.</Text>
            </View>
            <Link href={`/recipe/${recipe.id}/edit`} asChild>
              <View>
                <SecondaryButton fullWidth={false}>Open Fix Flow</SecondaryButton>
              </View>
            </Link>
          </View>
          <RecipeEditorForm recipe={recipe} onSubmit={handleRecipeUpdate} submitLabel="Save Edits" compact />
        </CooksyCard>
      ) : null}

      <CooksyCard className="mb-4">
        <Text className="text-[22px] font-bold text-ink">Ingredients</Text>
        {recipe.status === "processing" ? (
          <Text className="mt-4 text-[15px] leading-6 text-muted">Ingredients will appear here as soon as the recipe is ready.</Text>
        ) : (
          <IngredientChecklist
            ingredients={recipe.ingredients}
            onToggleIngredient={(ingredientId) => useCooksyStore.getState().toggleIngredientChecked(recipe.id, ingredientId)}
          />
        )}
      </CooksyCard>

      <CooksyCard>
        <Text className="mb-4 text-[22px] font-bold text-ink">Method</Text>
        {recipe.status === "processing" ? (
          <Text className="text-[15px] leading-6 text-muted">Cooksy is still structuring the method from the original source.</Text>
        ) : (
          <View style={{ gap: 12 }}>
            {recipe.steps.map((step, index) => (
              <StepCard key={step.id} step={step} index={index} />
            ))}
          </View>
        )}
      </CooksyCard>

      <View className="mt-4 flex-row items-center justify-between">
        <Text className="text-[13px] text-muted">
          Something wrong with this recipe?
        </Text>
        <ReportContentButton recipeId={recipe.id} />
      </View>
    </ScreenContainer>
  );
}
