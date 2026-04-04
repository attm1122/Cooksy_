import { Link } from "expo-router";
import { useMemo, useState } from "react";
import { Text, View } from "react-native";

import { AppHeader } from "@/components/common/AppHeader";
import { CooksyCard } from "@/components/common/CooksyCard";
import { PlatformBadge } from "@/components/common/PlatformBadge";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { SearchInput } from "@/components/common/SearchInput";
import { RecipeThumbnail } from "@/components/recipe/RecipeThumbnail";
import { useRecentRecipes } from "@/hooks/use-recipes";
import { formatMinutes } from "@/utils/time";

export default function RecipesScreen() {
  const { data: recipes = [] } = useRecentRecipes();
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

      <View style={{ gap: 14 }}>
        {filteredRecipes.map((recipe) => (
          <Link key={recipe.id} href={`/recipe/${recipe.id}`} asChild>
            <CooksyCard className="p-4">
              <View style={{ gap: 14 }}>
                <RecipeThumbnail recipe={recipe} size="compact" timeLabel={formatMinutes(recipe.totalTimeMinutes)} />
                <View>
                  <Text className="mb-1 text-[18px] font-bold text-ink">{recipe.title}</Text>
                  <Text className="mb-3 text-[14px] text-muted">{recipe.description}</Text>
                </View>
                <View className="flex-row items-center justify-between">
                  <PlatformBadge platform={recipe.source.platform} />
                  <Text className="text-[13px] font-semibold text-muted">{recipe.totalTimeMinutes} min total</Text>
                </View>
              </View>
            </CooksyCard>
          </Link>
        ))}
      </View>
    </ScreenContainer>
  );
}
