import { Link, usePathname } from "expo-router";
import { BookOpen, House, Library, UserCircle2 } from "lucide-react-native";
import { Pressable, Text, View } from "react-native";

const navItems = [
  {
    key: "home",
    label: "Home",
    href: "/" as const,
    icon: House,
    matches: (pathname: string) => pathname === "/" || pathname.startsWith("/processing")
  },
  {
    key: "recipes",
    label: "Recipes",
    href: "/recipes" as const,
    icon: Library,
    matches: (pathname: string) => pathname === "/recipes" || pathname.startsWith("/recipe/")
  },
  {
    key: "books",
    label: "Books",
    href: "/books" as const,
    icon: BookOpen,
    matches: (pathname: string) => pathname === "/books" || pathname.startsWith("/books/")
  },
  {
    key: "profile",
    label: "Profile",
    href: "/profile" as const,
    icon: UserCircle2,
    matches: (pathname: string) => pathname === "/profile"
  }
] as const;

export const PersistentTabNav = () => {
  const pathname = usePathname();

  return (
    <View className="mx-5 mb-5 mt-3 flex-row rounded-full border border-line bg-white px-2 py-2 shadow-card">
      {navItems.map((item) => {
        const Icon = item.icon;
        const isFocused = item.matches(pathname);

        return (
          <Link key={item.key} href={item.href} asChild>
            <Pressable
              accessibilityRole="link"
              accessibilityState={isFocused ? { selected: true } : {}}
              className={`flex-1 items-center rounded-full px-2 py-3 ${isFocused ? "bg-brand-yellow-soft" : ""}`}
            >
              <Icon size={18} color="#111111" />
              <Text className="mt-1 text-[12px] font-semibold text-soft-ink">{item.label}</Text>
            </Pressable>
          </Link>
        );
      })}
    </View>
  );
};
