import { Tabs } from "expo-router";

import { BottomTabBar } from "@/components/navigation/BottomTabBar";

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false
      }}
      tabBar={(props) => <BottomTabBar {...props} />}
    >
      <Tabs.Screen name="index" />
      <Tabs.Screen name="recipes" />
      <Tabs.Screen name="books" />
      <Tabs.Screen name="profile" />
    </Tabs>
  );
}
