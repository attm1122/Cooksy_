import type { PropsWithChildren } from "react";
import { View } from "react-native";

type CooksyCardProps = PropsWithChildren<{
  className?: string;
}>;

export const CooksyCard = ({ children, className = "" }: CooksyCardProps) => (
  <View className={`rounded-[26px] border border-line bg-surface p-5 shadow-card ${className}`}>{children}</View>
);
