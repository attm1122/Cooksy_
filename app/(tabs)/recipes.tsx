import { Link } from "expo-router";
import { AlertCircle, LoaderCircle } from "lucide-react-native";
import { useMemo, useState } from "react";
import { Text, View } from "react-native";

import { AppHeader } from "@/components/common/AppHeader";
import { CooksyCard } from "@/components/common/CooksyCard";
import { EmptyState } from "@/components/common/EmptyState";
import { PlatformBadge } from "@/components/common/PlatformBadge";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { SearchInput } from "@/components/common/SearchInput";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { useCooksyStore } from "@/store/use-cooksy-store";
import { formatMinutes } from "@/utils/time";

export default function RecipesScreen() {
  const recipes = useCooksyStore((state) => state.recipes);
  const recipesHydrationError = useCooksyStore((state) => state.recipesHydrationError);
  const [query, setQuery] = useState("");

  const filteredRecipes = useMemo(
    () =>
      recipes.filter((recipe) => recipe.title.toLowerCase().includes(query.toLowerCase()) || recipe.tags.join(" ").toLowerCase().includes(query.toLowerCase())),
    [query, recipes]
  );

  return (
    <ScreenContainer>
      <AppHeader />
      <Text className="mb-3 text-[28px] font-bold text-ink">Recipes library</Text>
      <Text className="mb-5 text-[15px] leading-6 text-muted">
        Your saved recipes, imports, and polished versions all live here.
      </Text>

      <View className="mb-5">
        <SearchInput value={query} onChangeText={setQuery} placeholder="Search recipes or tags" />
      </View>

      {filteredRecipes.length ? (
        <View style={{ gap: 14 }}>
          {filteredRecipes.map((recipe) => (
            <Link key={recipe.id} href={`/recipe/${recipe.id}`} asChild>
              <CooksyCard className="p-4">
                <View style={{ gap: 14 }}>
                  <RecipeThumbnail recipe={recipe} size="compact" timeLabel={formatMinutes(recipe.totalTimeMinutes)} />
                  <View>
                    <Text className="mb-1 text-[18px] font-bold text-ink">{recipe.title}</Text>
                    <Text className="mb-3 text-[14px] text-muted">
                      {recipe.status === "processing" ? "Generating recipe..." : recipe.description}
                    </Text>
                  </View>
                  <View className="flex-row items-center justify-between">
                    <View className="flex-row flex-wrap items-center" style={{ gap: 8 }}>
                      <PlatformBadge platform={recipe.source.platform} />
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
                    <Text className="text-[13px] font-semibold text-muted">
                      {recipe.status === "processing"
                        ? "Saved just now"
                        : recipe.status === "failed"
                          ? "Import incomplete"
                          : `${recipe.totalTimeMinutes} min total`}
                    </Text>
                  </View>
                </View>
              </CooksyCard>
            </Link>
          ))}
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
              ? "Try a different recipe name or clear the search to see everything you’ve saved."
              : "Paste a TikTok, Instagram Reel, or YouTube link and Cooksy will turn it into something you can cook."
          }
        />
      )}
    </ScreenContainer>
  );
}
