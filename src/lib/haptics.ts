/**
 * Haptic feedback utility
 * 
 * Provides consistent haptic feedback across the app for key user actions.
 * Uses expo-haptics when available, with graceful fallback for web/non-native platforms.
 * 
 * To enable: install expo-haptics (`npx expo install expo-haptics`)
 * and uncomment the import below.
 */

// import * as Haptics from "expo-haptics";

const isNative = typeof navigator !== "undefined" && navigator.product !== "ReactNative";

const trigger = (type: "light" | "medium" | "heavy" | "success" | "warning" | "error") => {
  // Uncomment when expo-haptics is installed:
  // if (!isNative) return;
  // 
  // try {
  //   switch (type) {
  //     case "light":
  //     case "medium":
  //     case "heavy":
  //       Haptics.impactAsync(
  //         type === "light" 
  //           ? Haptics.ImpactFeedbackStyle.Light 
  //           : type === "medium" 
  //             ? Haptics.ImpactFeedbackStyle.Medium 
  //             : Haptics.ImpactFeedbackStyle.Heavy
  //       );
  //       break;
  //     case "success":
  //     case "warning":
  //     case "error":
  //       Haptics.notificationAsync(
  //         type === "success" 
  //           ? Haptics.NotificationFeedbackType.Success 
  //           : type === "warning" 
  //             ? Haptics.NotificationFeedbackType.Warning 
  //             : Haptics.NotificationFeedbackType.Error
  //       );
  //       break;
  //   }
  // } catch {
  //   // Silently fail if haptics unavailable
  // }
};

export const haptics = {
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
  selection: () => {
    // if (isNative) {
    //   try {
    //     Haptics.selectionAsync();
    //   } catch {
    //     // Silently fail
    //   }
    // }
  }
};
