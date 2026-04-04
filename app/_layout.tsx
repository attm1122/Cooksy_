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

import { queryClient } from "@/lib/query-client";
import { fetchRecentRecipes } from "@/services/recipe-service";
import { useCooksyStore } from "@/store/use-cooksy-store";

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    Inter_500Medium,
    Inter_600SemiBold,
    Inter_700Bold
  });
  const mergeRecipes = useCooksyStore((state) => state.mergeRecipes);

  useEffect(() => {
    if (loaded || error) {
      SplashScreen.hideAsync();
    }
  }, [error, loaded]);

  useEffect(() => {
    if (!loaded) {
      return;
    }

    fetchRecentRecipes()
      .then((recipes) => {
        mergeRecipes(recipes);
      })
      .catch(() => {
        return;
      });
  }, [loaded, mergeRecipes]);

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
          <Stack.Screen name="books/[id]" />
        </Stack>
      </QueryClientProvider>
    </SafeAreaProvider>
  );
}
