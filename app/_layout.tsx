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
import { fetchRecipeBooks, fetchRecentRecipes } from "@/services/recipe-service";
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
        mergeRecipes(recipes);
      })
      .catch((fetchError) => {
        captureError(fetchError, {
          action: "hydrate_recipes_on_boot"
        });
      });

    fetchRecipeBooks()
      .then((books) => {
        mergeBooks(books);
      })
      .catch((fetchError) => {
        captureError(fetchError, {
          action: "hydrate_books_on_boot"
        });
      });
  }, [authStatus, loaded, mergeBooks, mergeRecipes]);

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
