import { Link, usePathname, useRouter } from "expo-router";
import { BookOpen, House, Library, Plus, UserCircle2 } from "lucide-react-native";
import { Pressable, Text, View } from "react-native";

const leftItems = [
  {
    key: "home",
    label: "Home",
    href: "/home" as const,
    icon: House,
    matches: (pathname: string) => pathname === "/home" || pathname.startsWith("/processing")
  },
  {
    key: "recipes",
    label: "Recipes",
    href: "/recipes" as const,
    icon: Library,
    matches: (pathname: string) => pathname === "/recipes" || pathname.startsWith("/recipe/")
  }
] as const;

const rightItems = [
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
  const router = useRouter();

  const renderItem = (item: { key: string; label: string; href: string; icon: typeof House; matches: (p: string) => boolean }) => {
    const Icon = item.icon;
    const isFocused = item.matches(pathname);
    return (
      <Link key={item.key} href={item.href as never} asChild>
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
  };

  return (
    <View className="mx-5 mb-5 mt-3 flex-row items-center rounded-full border border-line bg-white px-2 py-2 shadow-card">
      {leftItems.map(renderItem)}

      <Pressable
        onPress={() => router.push("/home" as never)}
        accessibilityLabel="Import recipe"
        accessibilityRole="button"
        style={{
          width: 52,
          height: 52,
          borderRadius: 26,
          backgroundColor: "#111111",
          alignItems: "center",
          justifyContent: "center",
          marginHorizontal: 6,
          shadowColor: "#111111",
          shadowOpacity: 0.2,
          shadowRadius: 10,
          shadowOffset: { width: 0, height: 4 },
          elevation: 6
        }}
      >
        <Plus size={22} color="#FFFFFF" strokeWidth={2.5} />
      </Pressable>

      {rightItems.map(renderItem)}
    </View>
  );
};
