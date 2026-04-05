import type { PropsWithChildren } from "react";
import { ActivityIndicator, Pressable, Text, View } from "react-native";

import { useHaptics } from "@/hooks/use-haptics";

type ButtonProps = PropsWithChildren<{
  onPress?: () => void;
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  /** Enable haptic feedback on press (default: true) */
  haptic?: boolean;
}>;

const labelClassName = "text-[15px] font-semibold";

export const PrimaryButton = ({
  children,
  onPress,
  disabled,
  loading,
  fullWidth = true,
  haptic = true
}: ButtonProps) => {
  const haptics = useHaptics();
  
  const handlePress = () => {
    if (haptic && !disabled && !loading) {
      haptics.medium();
    }
    onPress?.();
  };

  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled || loading}
      onPress={handlePress}
      className={`items-center justify-center rounded-full bg-brand-yellow px-5 py-4 active:opacity-80 ${
        fullWidth ? "w-full" : ""
      } ${disabled ? "opacity-50" : ""}`}
    >
      {loading ? (
        <ActivityIndicator color="#111111" />
      ) : typeof children === "string" ? (
        <Text className={`${labelClassName} text-ink`}>{children}</Text>
      ) : (
        <View>{children}</View>
      )}
    </Pressable>
  );
};

export const SecondaryButton = ({ 
  children, 
  onPress, 
  disabled, 
  fullWidth = false,
  haptic = true
}: ButtonProps) => {
  const haptics = useHaptics();
  
  const handlePress = () => {
    if (haptic && !disabled) {
      haptics.light();
    }
    onPress?.();
  };

  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      onPress={handlePress}
      className={`items-center justify-center rounded-full border border-line bg-white px-5 py-4 active:bg-cream ${
        fullWidth ? "w-full" : ""
      } ${disabled ? "opacity-50" : ""}`}
    >
      {typeof children === "string" ? (
        <Text className={`${labelClassName} text-soft-ink`}>{children}</Text>
      ) : (
        <View>{children}</View>
      )}
    </Pressable>
  );
};

export const TertiaryButton = ({ 
  children, 
  onPress, 
  disabled, 
  fullWidth = false,
  haptic = true
}: ButtonProps) => {
  const haptics = useHaptics();
  
  const handlePress = () => {
    if (haptic && !disabled) {
      haptics.light();
    }
    onPress?.();
  };

  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      onPress={handlePress}
      className={`items-center justify-center rounded-full px-4 py-3 active:opacity-70 ${
        fullWidth ? "w-full" : ""
      } ${disabled ? "opacity-50" : ""}`}
    >
      {typeof children === "string" ? (
        <Text className={`${labelClassName} text-muted`}>{children}</Text>
      ) : (
        <View>{children}</View>
      )}
    </Pressable>
  );
};

type IconButtonProps = PropsWithChildren<{
  onPress?: () => void;
  disabled?: boolean;
  haptic?: boolean;
  impact?: "light" | "medium";
}>;

/** Icon button with haptic feedback - useful for touchable icons */
export const IconButton = ({
  children,
  onPress,
  disabled,
  haptic = true,
  impact = "light"
}: IconButtonProps) => {
  const haptics = useHaptics();
  
  const handlePress = () => {
    if (haptic && !disabled) {
      if (impact === "light") {
        haptics.light();
      } else {
        haptics.medium();
      }
    }
    onPress?.();
  };

  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      onPress={handlePress}
      className={`items-center justify-center active:opacity-60 ${disabled ? "opacity-50" : ""}`}
    >
      {children}
    </Pressable>
  );
};
