import { Text, View } from "react-native";

type EmptyStateProps = {
  title: string;
  description: string;
};

export const EmptyState = ({ title, description }: EmptyStateProps) => (
  <View className="items-center rounded-[26px] border border-dashed border-line bg-surface-alt px-6 py-10">
    <Text className="mb-2 text-[20px] font-bold text-ink">{title}</Text>
    <Text className="max-w-[360px] text-center text-[15px] leading-6 text-muted">{description}</Text>
  </View>
);
