import { BookOpen, House, Library, UserCircle2 } from "lucide-react-native";
import type { BottomTabBarProps } from "@react-navigation/bottom-tabs";
import { Pressable, Text, View } from "react-native";

const iconMap = {
  index: House,
  recipes: Library,
  books: BookOpen,
  profile: UserCircle2
} as const;

const labelMap = {
  index: "Home",
  recipes: "Recipes",
  books: "Books",
  profile: "Profile"
} as const;

export const BottomTabBar = ({ state, descriptors, navigation }: BottomTabBarProps) => (
  <View className="mx-5 mb-5 flex-row rounded-full border border-line bg-white px-2 py-2 shadow-card">
    {state.routes.map((route, index) => {
      const isFocused = state.index === index;
      const { options } = descriptors[route.key];
      const onPress = () => {
        const event = navigation.emit({
          type: "tabPress",
          target: route.key,
          canPreventDefault: true
        });

        if (!isFocused && !event.defaultPrevented) {
          navigation.navigate(route.name, route.params);
        }
      };

      const Icon = iconMap[route.name as keyof typeof iconMap];
      const label = labelMap[route.name as keyof typeof labelMap];

      return (
        <Pressable
          key={route.key}
          accessibilityState={isFocused ? { selected: true } : {}}
          accessibilityLabel={options.tabBarAccessibilityLabel}
          onPress={onPress}
          className={`flex-1 items-center rounded-full px-2 py-3 ${isFocused ? "bg-brand-yellow-soft" : ""}`}
        >
          <Icon size={18} color="#111111" />
          <Text className="mt-1 text-[12px] font-semibold text-soft-ink">{label}</Text>
        </Pressable>
      );
    })}
  </View>
);
