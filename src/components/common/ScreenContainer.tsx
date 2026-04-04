import type { PropsWithChildren } from "react";
import { ScrollView, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

type ScreenContainerProps = PropsWithChildren<{
  scroll?: boolean;
}>;

export const ScreenContainer = ({ children, scroll = true }: ScreenContainerProps) => {
  if (scroll) {
    return (
      <SafeAreaView className="flex-1 bg-cream">
        <ScrollView contentContainerClassName="mx-auto w-full max-w-[1120px] px-5 pb-10 pt-3">
          {children}
        </ScrollView>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView className="flex-1 bg-cream">
      <View className="mx-auto flex-1 w-full max-w-[1120px] px-5 pb-10 pt-3">{children}</View>
    </SafeAreaView>
  );
};
