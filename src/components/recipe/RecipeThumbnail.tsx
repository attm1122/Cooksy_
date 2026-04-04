import { LinearGradient } from "expo-linear-gradient";
import { Clock3, LoaderCircle } from "lucide-react-native";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  ActivityIndicator,
  Animated,
  Image,
  Pressable,
  Text,
  View,
  type ImageStyle,
  type StyleProp,
  type ViewStyle
} from "react-native";

import { PlatformBadge } from "@/components/common/PlatformBadge";
import { generateFallbackThumbnail } from "@/features/recipes/services/thumbnailService";
import type { Recipe } from "@/types/recipe";

type RecipeThumbnailProps = {
  recipe: Recipe;
  aspectRatio?: number;
  timeLabel?: string;
  size?: "hero" | "card" | "compact";
  onPress?: () => void;
  style?: StyleProp<ViewStyle>;
  imageStyle?: StyleProp<ImageStyle>;
  showTitle?: boolean;
};

const fallbackPaletteMap: Record<string, readonly [string, string, string]> = {
  "golden-sear": ["#F5C400", "#D88B1F", "#6E4422"],
  "paprika-glow": ["#F0A33A", "#C15A2E", "#512814"],
  "toast-cream": ["#F6D98B", "#C18843", "#6E4B2C"],
  "copper-pan": ["#F1BF5D", "#9A5E2D", "#3A2218"]
};

const sizeMap = {
  hero: {
    title: "text-[28px]",
    subtitle: "text-[15px]"
  },
  card: {
    title: "text-[18px]",
    subtitle: "text-[13px]"
  },
  compact: {
    title: "text-[16px]",
    subtitle: "text-[12px]"
  }
} as const;

export const RecipeThumbnail = ({
  recipe,
  aspectRatio = 16 / 9,
  timeLabel,
  size = "card",
  onPress,
  style,
  imageStyle,
  showTitle = true
}: RecipeThumbnailProps) => {
  const [loading, setLoading] = useState(Boolean(recipe.thumbnailUrl));
  const [failed, setFailed] = useState(false);
  const fadeAnim = useRef(new Animated.Value(recipe.thumbnailUrl ? 0 : 1)).current;
  const shimmerAnim = useRef(new Animated.Value(0.35)).current;
  const enableMotion = process.env.NODE_ENV !== "test";

  const fallbackStyleKey = useMemo(() => generateFallbackThumbnail(recipe), [recipe]);
  const palette = fallbackPaletteMap[fallbackStyleKey] ?? fallbackPaletteMap["golden-sear"];
  const Wrapper = onPress ? Pressable : View;

  useEffect(() => {
    if (!recipe.thumbnailUrl || failed) {
      fadeAnim.setValue(1);
      return;
    }

    if (!enableMotion) {
      fadeAnim.setValue(1);
      return;
    }

    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 260,
      useNativeDriver: true
    }).start();
  }, [enableMotion, fadeAnim, failed, recipe.thumbnailUrl]);

  useEffect(() => {
    if (!loading || failed) {
      shimmerAnim.setValue(0);
      return;
    }

    if (!enableMotion) {
      shimmerAnim.setValue(0.45);
      return;
    }

    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(shimmerAnim, {
          toValue: 0.7,
          duration: 900,
          useNativeDriver: true
        }),
        Animated.timing(shimmerAnim, {
          toValue: 0.25,
          duration: 900,
          useNativeDriver: true
        })
      ])
    );

    loop.start();

    return () => loop.stop();
  }, [enableMotion, failed, loading, shimmerAnim]);

  const content = (
    <>
      <View className="absolute inset-0">
        {recipe.thumbnailUrl && !failed ? (
          <>
            <Animated.View className="absolute inset-0" style={{ opacity: fadeAnim }}>
              <Image
                source={{ uri: recipe.thumbnailUrl }}
                resizeMode="cover"
                onLoadEnd={() => setLoading(false)}
                onError={() => {
                  setLoading(false);
                  setFailed(true);
                }}
                style={[{ width: "100%", height: "100%" }, imageStyle]}
              />
            </Animated.View>
            {loading ? (
              <Animated.View className="absolute inset-0 bg-[#22190E]" style={{ opacity: shimmerAnim }} />
            ) : null}
            {loading ? (
              <View className="absolute inset-0 items-center justify-center">
                <ActivityIndicator color="#FFFDF7" />
              </View>
            ) : null}
          </>
        ) : (
          <LinearGradient colors={palette} className="absolute inset-0" />
        )}
        <LinearGradient
          colors={["rgba(17,17,17,0.04)", "rgba(17,17,17,0.18)", "rgba(17,17,17,0.84)"]}
          locations={[0, 0.45, 1]}
          className="absolute inset-0"
        />
      </View>

      <View className="flex-1 justify-between p-4">
        <View className="flex-row items-start justify-between" style={{ gap: 12 }}>
          <PlatformBadge platform={recipe.source.platform} />
          {recipe.status === "processing" ? (
            <View className="flex-row items-center rounded-full bg-white/85 px-3 py-1" style={{ gap: 6 }}>
              <LoaderCircle size={12} color="#111111" />
              <Text className="text-[12px] font-semibold text-ink">Generating recipe...</Text>
            </View>
          ) : timeLabel ? (
            <View className="flex-row items-center rounded-full bg-white/85 px-3 py-1" style={{ gap: 6 }}>
              <Clock3 size={12} color="#111111" />
              <Text className="text-[12px] font-semibold text-ink">{timeLabel}</Text>
            </View>
          ) : null}
        </View>

        <View>
          {showTitle ? (
            <Text className={`font-bold leading-tight text-white ${sizeMap[size].title}`}>{recipe.title}</Text>
          ) : null}
          <Text className={`mt-1 font-medium text-[#F4EFE5] ${sizeMap[size].subtitle}`}>
            {recipe.status === "processing" ? recipe.processingMessage ?? "Generating recipe..." : `@${recipe.source.creator}`}
          </Text>
        </View>
      </View>
    </>
  );

  if (onPress) {
    return (
      <Pressable
        onPress={onPress}
        className="overflow-hidden rounded-[26px] bg-soft-ink"
        style={({ pressed }) => [
          { aspectRatio },
          style,
          pressed ? { transform: [{ scale: 0.985 }], opacity: 0.95 } : null
        ]}
      >
        {content}
      </Pressable>
    );
  }

  return (
    <Wrapper className="overflow-hidden rounded-[26px] bg-soft-ink" style={[{ aspectRatio }, style]}>
      {content}
    </Wrapper>
  );
};
