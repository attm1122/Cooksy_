import type { SourcePlatform } from "@/types/recipe";
import { detectPlatformFromUrl } from "@/features/recipes/lib/platform";

export const getSupportedPlatformFromUrl = (value: string): SourcePlatform | null => {
  try {
    return detectPlatformFromUrl(value);
  } catch {
    return null;
  }
};

export const isSupportedSourceUrl = (value: string) => getSupportedPlatformFromUrl(value) !== null;
