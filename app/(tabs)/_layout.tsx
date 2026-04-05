import { Tabs } from "expo-router";

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false
      }}
      tabBar={() => null}
    >
      <Tabs.Screen name="home" />
      <Tabs.Screen name="recipes" />
      <Tabs.Screen name="books" />
      <Tabs.Screen name="profile" />
    </Tabs>
  );
}
