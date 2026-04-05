/**
 * useHaptics hook
 * 
 * Provides haptic feedback that works consistently across iOS and Android.
 * Falls back gracefully on web or when haptics unavailable.
 * 
 * Usage:
 * const haptics = useHaptics();
 * 
 * // Light feedback on button press
 * <PrimaryButton onPress={() => {
 *   haptics.light();
 *   handleSubmit();
 * }}>
 * 
 * // Success feedback on completion
 * haptics.success();
 * 
 * // Error feedback on failure
 * haptics.error();
 */

import { useCallback } from "react";
import { Platform } from "react-native";

const isNative = Platform.OS === "ios" || Platform.OS === "android";
type HapticsModule = {
  impactAsync: (style: unknown) => Promise<void>;
  notificationAsync: (type: unknown) => Promise<void>;
  selectionAsync: () => Promise<void>;
  ImpactFeedbackStyle: {
    Light: unknown;
    Medium: unknown;
    Heavy: unknown;
  };
  NotificationFeedbackType: {
    Success: unknown;
    Warning: unknown;
    Error: unknown;
  };
};

let hapticsModule: HapticsModule | null = null;

const loadHapticsModule = (): HapticsModule | null => {
  if (!isNative) return null;
  if (hapticsModule) return hapticsModule;

  const globalRequire = globalThis as typeof globalThis & {
    require?: (moduleId: string) => unknown;
  };

  try {
    const loaded = globalRequire.require?.("expo-haptics");
    if (loaded && typeof loaded === "object") {
      hapticsModule = loaded as HapticsModule;
      return hapticsModule;
    }
  } catch {
    return null;
  }

  return null;
};

export const useHaptics = () => {
  const trigger = useCallback((
    type: "light" | "medium" | "heavy" | "success" | "warning" | "error"
  ) => {
    const ExpoHaptics = loadHapticsModule();
    if (!ExpoHaptics) return;

    try {
      switch (type) {
        case "light":
        case "medium":
        case "heavy":
          ExpoHaptics.impactAsync(
            type === "light" 
              ? ExpoHaptics.ImpactFeedbackStyle.Light 
              : type === "medium" 
                ? ExpoHaptics.ImpactFeedbackStyle.Medium 
                : ExpoHaptics.ImpactFeedbackStyle.Heavy
          );
          break;
        case "success":
        case "warning":
        case "error":
          ExpoHaptics.notificationAsync(
            type === "success" 
              ? ExpoHaptics.NotificationFeedbackType.Success 
              : type === "warning" 
                ? ExpoHaptics.NotificationFeedbackType.Warning 
                : ExpoHaptics.NotificationFeedbackType.Error
          );
          break;
      }
    } catch (error) {
      // Silently fail if haptics unavailable
      console.debug("[haptics] Failed to trigger:", error);
    }
  }, []);

  const selection = useCallback(() => {
    const ExpoHaptics = loadHapticsModule();
    if (!ExpoHaptics) return;

    try {
      ExpoHaptics.selectionAsync();
    } catch (error) {
      console.debug("[haptics] Selection failed:", error);
    }
  }, []);

  return {
    /** Light impact for subtle feedback (e.g., button taps) */
    light: () => trigger("light"),
    /** Medium impact for standard feedback (e.g., toggles, selections) */
    medium: () => trigger("medium"),
    /** Heavy impact for significant actions (e.g., delete confirmations) */
    heavy: () => trigger("heavy"),
    /** Success feedback for completed actions */
    success: () => trigger("success"),
    /** Warning feedback for cautionary actions */
    warning: () => trigger("warning"),
    /** Error feedback for failures */
    error: () => trigger("error"),
    /** Selection feedback for picker/item selection */
    selection
  };
};

export default useHaptics;
