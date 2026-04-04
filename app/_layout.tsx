import "@/../global.css";
import "react-native-gesture-handler";
import "react-native-url-polyfill/auto";

import { Inter_500Medium, Inter_600SemiBold, Inter_700Bold, useFonts } from "@expo-google-fonts/inter";
import { QueryClientProvider } from "@tanstack/react-query";
import { Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { useEffect } from "react";
import { SafeAreaProvider } from "react-native-safe-area-context";

import { ensureCooksySession, subscribeToCooksyAuth } from "@/lib/auth";
import { trackEvent } from "@/lib/analytics";
import { hasSupabaseConfig } from "@/lib/env";
import { captureError } from "@/lib/monitoring";
import { queryClient } from "@/lib/query-client";
import { fetchRecipeBooks, fetchRecentRecipes, pollImportJobUntilComplete } from "@/services/recipe-service";
import { useAuthStore } from "@/store/use-auth-store";
import { useCooksyStore } from "@/store/use-cooksy-store";

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    Inter_500Medium,
    Inter_600SemiBold,
    Inter_700Bold
  });
  const mergeBooks = useCooksyStore((state) => state.mergeBooks);
  const mergeRecipes = useCooksyStore((state) => state.mergeRecipes);
  const patchRecipe = useCooksyStore((state) => state.patchRecipe);
  const setRecipesHydrationError = useCooksyStore((state) => state.setRecipesHydrationError);
  const setBooksHydrationError = useCooksyStore((state) => state.setBooksHydrationError);
  const setLastCompletedRecipeId = useCooksyStore((state) => state.setLastCompletedRecipeId);
  const authStatus = useAuthStore((state) => state.status);
  const setAuthState = useAuthStore((state) => state.setAuthState);

  useEffect(() => {
    if (loaded || error) {
      SplashScreen.hideAsync();
      trackEvent("app_bootstrapped", {
        fontsLoaded: loaded,
        hasFontError: Boolean(error)
      });
    }
  }, [error, loaded]);

  useEffect(() => {
    if (!loaded) {
      return;
    }

    if (!hasSupabaseConfig) {
      setAuthState({
        status: "ready",
        userId: undefined,
        errorMessage: undefined
      });
      return;
    }

    setAuthState({ status: "loading", errorMessage: undefined });
    ensureCooksySession().then(({ userId, errorMessage }) => {
      trackEvent(errorMessage ? "auth_session_failed" : "auth_session_ready", {
        hasUser: Boolean(userId)
      });
      setAuthState({
        status: errorMessage ? "error" : "ready",
        userId,
        errorMessage
      });
    });

    const unsubscribe = subscribeToCooksyAuth((userId) => {
      setAuthState({
        status: "ready",
        userId,
        errorMessage: undefined
      });
    });

    return unsubscribe;
  }, [loaded, setAuthState]);

  useEffect(() => {
    if (!loaded || authStatus === "loading") {
      return;
    }

    fetchRecentRecipes()
      .then((recipes) => {
        setRecipesHydrationError(undefined);
        mergeRecipes(recipes);

        recipes
          .filter((recipe) => recipe.status === "processing" && recipe.importJobId)
          .forEach((recipe) => {
            void pollImportJobUntilComplete(recipe.importJobId!)
              .then((completedRecipe) => {
                mergeRecipes([
                  {
                    ...completedRecipe,
                    importJobId: completedRecipe.importJobId ?? recipe.importJobId,
                    status: "ready",
                    processingMessage: undefined,
                    isSaved: true
                  }
                ]);
                setLastCompletedRecipeId(completedRecipe.id);
              })
              .catch((resumeError) => {
                patchRecipe(recipe.id, {
                  status: "failed",
                  processingMessage: resumeError instanceof Error ? resumeError.message : "Recipe generation failed",
                  confidence: "low",
                  confidenceScore: 28,
                  confidenceNote: "Cooksy could not confidently reconstruct this recipe from the source.",
                  missingFields: ["Recipe generation failed"],
                  inferredFields: []
                });
                captureError(resumeError, {
                  action: "resume_processing_recipe_on_boot",
                  recipeId: recipe.id,
                  jobId: recipe.importJobId
                });
              });
          });
      })
      .catch((fetchError) => {
        setRecipesHydrationError(fetchError instanceof Error ? fetchError.message : "Could not load recipes");
        captureError(fetchError, {
          action: "hydrate_recipes_on_boot"
        });
      });

    fetchRecipeBooks()
      .then((books) => {
        setBooksHydrationError(undefined);
        mergeBooks(books);
      })
      .catch((fetchError) => {
        setBooksHydrationError(fetchError instanceof Error ? fetchError.message : "Could not load recipe books");
        captureError(fetchError, {
          action: "hydrate_books_on_boot"
        });
      });
  }, [
    authStatus,
    loaded,
    mergeBooks,
    mergeRecipes,
    patchRecipe,
    setBooksHydrationError,
    setLastCompletedRecipeId,
    setRecipesHydrationError
  ]);

  if (!loaded && !error) {
    return null;
  }

  return (
    <SafeAreaProvider>
      <QueryClientProvider client={queryClient}>
        <StatusBar style="dark" />
        <Stack
          screenOptions={{
            headerShown: false,
            contentStyle: {
              backgroundColor: "#FFFDF7"
            }
          }}
        >
          <Stack.Screen name="(tabs)" />
          <Stack.Screen name="processing" options={{ presentation: "card" }} />
          <Stack.Screen name="recipe/[id]" />
          <Stack.Screen name="recipe/[id]/edit" />
          <Stack.Screen name="recipe/[id]/cook" options={{ presentation: "fullScreenModal" }} />
          <Stack.Screen name="recipe/[id]/grocery" />
          <Stack.Screen name="books/[id]" />
        </Stack>
      </QueryClientProvider>
    </SafeAreaProvider>
  );
}
