import type { PropsWithChildren } from "react";
import { ActivityIndicator, Pressable, Text, View } from "react-native";

type ButtonProps = PropsWithChildren<{
  onPress?: () => void;
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
}>;

const labelClassName = "text-[15px] font-semibold";

export const PrimaryButton = ({
  children,
  onPress,
  disabled,
  loading,
  fullWidth = true
}: ButtonProps) => (
  <Pressable
    accessibilityRole="button"
    disabled={disabled || loading}
    onPress={onPress}
    className={`items-center justify-center rounded-full bg-brand-yellow px-5 py-4 ${fullWidth ? "w-full" : ""} ${
      disabled ? "opacity-50" : ""
    }`}
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

export const SecondaryButton = ({ children, onPress, disabled, fullWidth = false }: ButtonProps) => (
  <Pressable
    accessibilityRole="button"
    disabled={disabled}
    onPress={onPress}
    className={`items-center justify-center rounded-full border border-line bg-white px-5 py-4 ${
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
