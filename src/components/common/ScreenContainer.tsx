import type { PropsWithChildren } from "react";
import { KeyboardAvoidingView, Platform, ScrollView, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { AppHeader } from "@/components/common/AppHeader";
import { PersistentTabNav } from "@/components/navigation/PersistentTabNav";

type ScreenContainerProps = PropsWithChildren<{
  scroll?: boolean;
  showHeader?: boolean;
  showBottomNav?: boolean;
  /** Enable keyboard avoiding behavior (useful for forms on mobile) */
  keyboardAvoiding?: boolean;
}>;

const BEHAVIOR = Platform.OS === "ios" ? "padding" : "height";

export const ScreenContainer = ({
  children,
  scroll = true,
  showHeader = true,
  showBottomNav = true,
  keyboardAvoiding = false
}: ScreenContainerProps) => {
  const content = scroll ? (
    <ScrollView 
      contentContainerClassName="mx-auto w-full max-w-[1120px] px-5 pb-14"
      keyboardShouldPersistTaps="handled"
    >
      {children}
    </ScrollView>
  ) : (
    <View className="mx-auto flex-1 w-full max-w-[1120px] px-5 pb-6 pt-3">
      {showHeader ? <AppHeader /> : null}
      <View className="flex-1">{children}</View>
    </View>
  );

  const wrappedContent = keyboardAvoiding ? (
    <KeyboardAvoidingView 
      behavior={BEHAVIOR}
      className="flex-1"
      keyboardVerticalOffset={Platform.OS === "ios" ? 100 : 0}
    >
      {content}
    </KeyboardAvoidingView>
  ) : content;

  if (scroll) {
    return (
      <SafeAreaView className="flex-1 bg-cream">
        {showHeader ? (
          <View className="mx-auto w-full max-w-[1120px] px-5 pt-3">
            <AppHeader />
          </View>
        ) : null}
        {wrappedContent}
        {showBottomNav ? <PersistentTabNav /> : null}
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView className="flex-1 bg-cream">
      {wrappedContent}
      {showBottomNav ? <PersistentTabNav /> : null}
    </SafeAreaView>
  );
};
