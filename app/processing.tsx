import { useLocalSearchParams, router } from "expo-router";
import { AlertCircle, CheckCircle2, LoaderCircle, RotateCw } from "lucide-react-native";
import { useEffect, useMemo, useRef } from "react";
import { Alert, Text, View } from "react-native";

import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { PrimaryButton } from "@/components/common/Buttons";
import { useImportRecipe } from "@/hooks/use-recipes";
import { useCooksyStore } from "@/store/use-cooksy-store";

const stages = [
  { key: "queued", label: "Queueing import" },
  { key: "extracting", label: "Extracting video content" },
  { key: "ingredients", label: "Identifying ingredients" },
  { key: "steps", label: "Building cooking steps" }
] as const;

export default function ProcessingScreen() {
  const { url } = useLocalSearchParams<{ url?: string }>();
  const importProgress = useCooksyStore((state) => state.importProgress);
  const setImportProgress = useCooksyStore((state) => state.setImportProgress);
  const saveRecipe = useCooksyStore((state) => state.saveRecipe);
  const setSelectedRecipe = useCooksyStore((state) => state.setSelectedRecipe);
  const startedImportUrlRef = useRef<string | undefined>(undefined);

  const mutation = useImportRecipe((progress) => setImportProgress(progress));

  useEffect(() => {
    if (!url || startedImportUrlRef.current === url) {
      return;
    }

    startedImportUrlRef.current = url;
    setImportProgress({ url, stage: "queued", progress: 0.08, detail: "Preparing the import job" });

    mutation.mutate(url, {
      onSuccess: (recipe) => {
        saveRecipe(recipe);
        setSelectedRecipe(recipe.id);
        router.replace(`/recipe/${recipe.id}`);
      },
      onError: (error) => {
        setImportProgress({
          url,
          stage: "error",
          progress: 1,
          detail: "Import failed",
          errorMessage: error instanceof Error ? error.message : "Recipe import failed"
        });
      }
    });
  }, [mutation, saveRecipe, setImportProgress, setSelectedRecipe, url]);

  const activeIndex = useMemo(
    () => Math.max(stages.findIndex((stage) => stage.key === importProgress.stage), 0),
    [importProgress.stage]
  );

  return (
    <ScreenContainer>
      <CooksyCard>
        <Text className="mb-2 text-[28px] font-bold text-ink">Building your recipe</Text>
        <Text className="mb-6 text-[15px] leading-6 text-muted">
          Cooksy is cleaning up the source content, inferring quantities, and structuring the method into a recipe view.
        </Text>
        <Text className="mb-4 text-[14px] font-semibold text-soft-ink">{importProgress.detail}</Text>
        {importProgress.errorMessage ? (
          <Text className="mb-4 text-[14px] leading-6 text-danger">{importProgress.errorMessage}</Text>
        ) : null}

        <View className="mb-6 h-2 overflow-hidden rounded-full bg-surface-alt">
          <View className="h-full rounded-full bg-brand-yellow" style={{ width: `${importProgress.progress * 100}%` }} />
        </View>

        <View style={{ gap: 12 }}>
          {importProgress.stage === "error" ? (
          <View className="flex-row items-center rounded-[22px] border border-danger bg-[#FFF1EE] px-4 py-4" style={{ gap: 12 }}>
            <AlertCircle size={20} color="#8F4A1D" />
            <Text className="flex-1 text-[15px] font-semibold text-soft-ink">Import failed</Text>
          </View>
        ) : (
          stages.map((stage, index) => {
            const complete = index < activeIndex || importProgress.stage === "complete";
            const active = index === activeIndex && !["complete", "error"].includes(importProgress.stage);

            return (
              <View
                key={stage.key}
                className={`flex-row items-center rounded-[22px] border px-4 py-4 ${
                  active ? "border-[#F0D96B] bg-brand-yellow-soft" : "border-line bg-white"
                }`}
                style={{ gap: 12 }}
              >
                {complete ? (
                  <CheckCircle2 size={20} color="#1D8F5F" />
                ) : (
                  <LoaderCircle size={20} color="#111111" />
                )}
                <Text className="text-[15px] font-semibold text-soft-ink">{stage.label}</Text>
              </View>
            );
          })
        )}
        {importProgress.stage === "error" && url && (
          <PrimaryButton
            onPress={() => {
              if (!url) return;
              startedImportUrlRef.current = undefined;
              setImportProgress({ url, stage: "queued", progress: 0.08, detail: "Retrying import..." });
              mutation.mutate(url, {
                onSuccess: (recipe) => {
                  saveRecipe(recipe);
                  setSelectedRecipe(recipe.id);
                  router.replace(`/recipe/${recipe.id}`);
                },
                onError: (error) => {
                  setImportProgress({
                    url,
                    stage: "error",
                    progress: 1,
                    detail: "Import failed",
                    errorMessage: error instanceof Error ? error.message : "Recipe import failed"
                  });
                }
              });
            }}
          >
            <View className="flex-row items-center" style={{ gap: 8 }}>
              <RotateCw size={16} color="#111111" />
              <Text className="text-[15px] font-semibold text-ink">Try Again</Text>
            </View>
          </PrimaryButton>
        )}
        </View>
      </CooksyCard>
    </ScreenContainer>
  );
}
