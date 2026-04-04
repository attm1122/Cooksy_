import { View } from "react-native";

import { CooksyLogo } from "@/components/common/CooksyLogo";

export const AppHeader = () => (
  <View className="mb-5 flex-row items-center justify-between">
    <CooksyLogo size="md" />
  </View>
);
