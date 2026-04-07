import "@/../global.css";
import "react-native-gesture-handler";
import "react-native-url-polyfill/auto";

import { Platform } from "react-native";

import { Inter_500Medium, Inter_600SemiBold, Inter_700Bold, useFonts } from "@expo-google-fonts/inter";
import { QueryClientProvider } from "@tanstack/react-query";
import { router, Stack, usePathname } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { useEffect } from "react";
import { SafeAreaProvider } from "react-native-safe-area-context";

import { CookieConsent } from "@/components/common/CookieConsent";
import { ensureCooksySession, subscribeToCooksyAuth } from "@/lib/auth";
import { useSubscriptionStore } from "@/stores/subscription-store";
import { identifyUser, trackEvent } from "@/lib/analytics";
import { hasSupabaseConfig } from "@/lib/env";
import { addBreadcrumb, captureError, setMonitoringUser } from "@/lib/monitoring";
import { queryClient } from "@/lib/query-client";
import { fetchPendingImportJobs, fetchRecipeBooks, fetchRecentRecipes, pollImportJobUntilComplete } from "@/services/recipe-service";
import { useAuthStore } from "@/store/use-auth-store";
import { useCooksyStore } from "@/store/use-cooksy-store";
import type { Recipe, ThumbnailSource, SourcePlatform } from "@/types/recipe";

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
  const authUserId = useAuthStore((state) => state.userId);
  const setAuthState = useAuthStore((state) => state.setAuthState);
  const pathname = usePathname();

  // Hide splash screen when fonts are loaded
  useEffect(() => {
    if (loaded || error) {
      SplashScreen.hideAsync();
      trackEvent("app_bootstrapped", {
        fontsLoaded: loaded,
        hasFontError: Boolean(error)
      });
    }
  }, [error, loaded]);

  // Initialize auth session
  useEffect(() => {
    if (!loaded) {
      return;
    }

    if (!hasSupabaseConfig) {
      setAuthState({
        status: "ready",
        userId: undefined,
        email: undefined,
        fullName: undefined,
        errorMessage: undefined
      });
      return;
    }

    setAuthState({ status: "loading", errorMessage: undefined });
    ensureCooksySession().then(({ userId, email, fullName, errorMessage }) => {
      trackEvent(errorMessage ? "auth_session_failed" : "auth_session_ready", {
        hasUser: Boolean(userId)
      });
      setAuthState({
        status: errorMessage ? "error" : "ready",
        userId,
        email,
        fullName,
        errorMessage
      });
    });

    const unsubscribe = subscribeToCooksyAuth(({ userId, email, fullName }) => {
      setAuthState({
        status: "ready",
        userId,
        email,
        fullName,
        errorMessage: undefined
      });
    });

    return unsubscribe;
  }, [loaded, setAuthState]);

  useEffect(() => {
    if (!loaded || authStatus !== "ready") {
      return;
    }

    const isRootRoute = pathname === "/";
    const isAuthRoute = pathname === "/auth";
    const isLegalRoute = pathname.startsWith("/legal");
    const isDemoRoute = pathname === "/demo";
    const isPrivacyRedirect = pathname === "/privacy" || pathname === "/terms";
    const isPublicRoute = isRootRoute || isAuthRoute || isLegalRoute || isDemoRoute || isPrivacyRedirect;

    if (!authUserId) {
      if (!isPublicRoute) {
        router.replace("/auth" as never);
      }
      return;
    }

    if (isAuthRoute) {
      router.replace("/home" as never);
    }
  }, [authStatus, authUserId, loaded, pathname]);

  // Identify user for analytics/monitoring when auth is ready
  useEffect(() => {
    if (authStatus === "ready" && authUserId) {
      identifyUser(authUserId);
      setMonitoringUser(authUserId);
      addBreadcrumb("User identified", "auth", { userId: authUserId });
    }
  }, [authStatus, authUserId]);

  // Initialize RevenueCat subscription store when user is authenticated
  useEffect(() => {
    if (authStatus === "ready" && authUserId && Platform.OS !== "web") {
      useSubscriptionStore.getState().initialize(authUserId);
    }
  }, [authStatus, authUserId]);

  // Hydrate data ONLY when auth is confirmed ready
  useEffect(() => {
    // Gate data hydration on confirmed auth readiness
    if (!loaded || authStatus !== "ready" || !authUserId) {
      return;
    }

    let isCancelled = false;

    const hydrateData = async () => {
      addBreadcrumb("Starting data hydration", "hydration");

      try {
        // Fetch recipes (including pending/processing ones)
        const recipes = await fetchRecentRecipes();
        
        if (isCancelled) return;
        
        setRecipesHydrationError(undefined);
        mergeRecipes(recipes);
        
        trackEvent("recipes_hydrated", {
          count: recipes.length,
          processingCount: recipes.filter((r) => r.status === "processing").length
        });

        // Resume polling for any processing recipes
        recipes
          .filter((recipe) => recipe.status === "processing" && recipe.importJobId)
          .forEach((recipe) => {
            addBreadcrumb("Resuming recipe polling", "hydration", {
              recipeId: recipe.id,
              jobId: recipe.importJobId
            });

            void pollImportJobUntilComplete(recipe.importJobId!)
              .then((completedRecipe) => {
                if (isCancelled) return;
                
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
                
                trackEvent("recipe_import_resumed_completed", {
                  recipeId: completedRecipe.id,
                  jobId: recipe.importJobId
                });
              })
              .catch((resumeError) => {
                if (isCancelled) return;
                
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
      } catch (fetchError) {
        if (isCancelled) return;
        
        setRecipesHydrationError(fetchError instanceof Error ? fetchError.message : "Could not load recipes");
        captureError(fetchError, {
          action: "hydrate_recipes_on_boot"
        });
      }

      // Fetch pending import jobs (not just completed recipes)
      try {
        const pendingJobs = await fetchPendingImportJobs();
        
        if (isCancelled) return;
        
        if (pendingJobs.length > 0) {
          addBreadcrumb("Found pending import jobs", "hydration", {
            count: pendingJobs.length
          });

          // Create placeholder recipes for pending jobs
          const pendingRecipes: Recipe[] = pendingJobs.map((job) => ({
            id: `pending-${job.id}`,
            status: "processing" as const,
            importJobId: job.id,
            processingMessage: job.stage_description || "Generating recipe...",
            title: "Recipe in progress",
            description: "Your recipe is being assembled from the source video.",
            heroNote: "Saved from a link you discovered. Cooksy is turning it into something you can actually cook.",
            imageLabel: "Imported recipe cover",
            thumbnailUrl: null,
            thumbnailSource: (job.source_platform as ThumbnailSource) || "generated",
            servings: 2,
            prepTimeMinutes: 0,
            cookTimeMinutes: 0,
            totalTimeMinutes: 0,
            confidence: "medium",
            confidenceScore: 0,
            confidenceNote: "Cooksy is still reconstructing the recipe from the source content.",
            inferredFields: [],
            missingFields: ["Recipe details still generating"],
            warnings: [],
            editableFields: [],
            isSaved: true,
            source: {
              creator: job.source_creator || "Saved source",
              url: job.source_url,
              platform: (job.source_platform as SourcePlatform) || "youtube"
            },
            ingredients: [],
            steps: [],
            tags: ["Processing"]
          }));

          mergeRecipes(pendingRecipes);

          // Start polling for each pending job
          pendingJobs.forEach((job) => {
            void pollImportJobUntilComplete(job.id)
              .then((completedRecipe) => {
                if (isCancelled) return;
                
                // Remove placeholder and add completed recipe
                mergeRecipes([
                  {
                    ...completedRecipe,
                    importJobId: job.id,
                    status: "ready",
                    processingMessage: undefined,
                    isSaved: true
                  }
                ]);
                setLastCompletedRecipeId(completedRecipe.id);
              })
              .catch((pollError) => {
                if (isCancelled) return;
                
                captureError(pollError, {
                  action: "poll_pending_job_on_boot",
                  jobId: job.id
                });
              });
          });

          trackEvent("pending_imports_hydrated", {
            count: pendingJobs.length
          });
        }
      } catch (pendingError) {
        // Non-critical error - just log it
        captureError(pendingError, {
          action: "hydrate_pending_imports"
        });
      }

      // Fetch recipe books
      try {
        const books = await fetchRecipeBooks();
        
        if (isCancelled) return;
        
        setBooksHydrationError(undefined);
        mergeBooks(books);
        
        trackEvent("books_hydrated", {
          count: books.length
        });
      } catch (fetchError) {
        if (isCancelled) return;
        
        setBooksHydrationError(fetchError instanceof Error ? fetchError.message : "Could not load recipe books");
        captureError(fetchError, {
          action: "hydrate_books_on_boot"
        });
      }

      addBreadcrumb("Data hydration complete", "hydration");
    };

    void hydrateData();

    return () => {
      isCancelled = true;
    };
  }, [
    authStatus,
    authUserId,
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
        <CookieConsent />
        <Stack
          screenOptions={{
            headerShown: false,
            contentStyle: {
              backgroundColor: "#FFFDF7"
            },
            // Enable gestures for iOS back navigation
            gestureEnabled: true,
            gestureDirection: "horizontal",
            // Platform-specific animation settings
            animation: Platform.OS === "ios" ? "default" : "fade_from_bottom"
          }}
        >
          <Stack.Screen name="(tabs)" />
          <Stack.Screen 
            name="processing" 
            options={{ 
              presentation: "card",
              // Prevent swipe to dismiss during processing
              gestureEnabled: false 
            }} 
          />
          <Stack.Screen 
            name="recipe/[id]" 
            options={{
              // Enable swipe back on iOS
              gestureEnabled: true
            }}
          />
          <Stack.Screen 
            name="recipe/[id]/edit" 
            options={{
              presentation: Platform.OS === "ios" ? "modal" : "card",
              gestureEnabled: true
            }}
          />
          <Stack.Screen 
            name="recipe/[id]/cook" 
            options={{ 
              presentation: "fullScreenModal",
              // Disable swipe to dismiss in cooking mode (must use exit button)
              gestureEnabled: false 
            }} 
          />
          <Stack.Screen 
            name="recipe/[id]/grocery" 
            options={{
              presentation: Platform.OS === "ios" ? "modal" : "card",
              gestureEnabled: true
            }}
          />
          <Stack.Screen 
            name="books/[id]" 
            options={{
              gestureEnabled: true
            }}
          />
        </Stack>
      </QueryClientProvider>
    </SafeAreaProvider>
  );
}
