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

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type HapticsModule = any;

const isNative = Platform.OS === "ios" || Platform.OS === "android";

let Haptics: HapticsModule | null = null;

// Lazy load expo-haptics only on native platforms
if (isNative) {
  try {
    // Dynamic require to prevent web bundling issues
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    Haptics = require("expo-haptics");
  } catch {
    // expo-haptics not installed
    // Silently skip - haptics are optional
  }
}

export const useHaptics = () => {
  const trigger = useCallback((
    type: "light" | "medium" | "heavy" | "success" | "warning" | "error"
  ) => {
    if (!isNative || !Haptics) return;

    try {
      switch (type) {
        case "light":
        case "medium":
        case "heavy":
          Haptics.impactAsync(
            type === "light" 
              ? Haptics.ImpactFeedbackStyle.Light 
              : type === "medium" 
                ? Haptics.ImpactFeedbackStyle.Medium 
                : Haptics.ImpactFeedbackStyle.Heavy
          );
          break;
        case "success":
        case "warning":
        case "error":
          Haptics.notificationAsync(
            type === "success" 
              ? Haptics.NotificationFeedbackType.Success 
              : type === "warning" 
                ? Haptics.NotificationFeedbackType.Warning 
                : Haptics.NotificationFeedbackType.Error
          );
          break;
      }
    } catch (error) {
      // Silently fail if haptics unavailable
      console.debug("[haptics] Failed to trigger:", error);
    }
  }, []);

  const selection = useCallback(() => {
    if (!isNative || !Haptics) return;

    try {
      Haptics.selectionAsync();
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
