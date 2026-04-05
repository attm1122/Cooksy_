import { Link, router, usePathname } from "expo-router";
import { ChevronLeft } from "lucide-react-native";
import { Pressable, Text, View } from "react-native";

import { CooksyLogo } from "@/components/common/CooksyLogo";

const topLevelRoutes = new Set(["/", "/recipes", "/books", "/profile"]);

const getBackHref = (pathname: string) => {
  if (pathname.startsWith("/books/")) {
    return "/books";
  }

  if (pathname.startsWith("/recipe/")) {
    return "/recipes";
  }

  return "/";
};

export const AppHeader = () => {
  const pathname = usePathname();
  const showBack = !topLevelRoutes.has(pathname);
  const backHref = getBackHref(pathname);

  const handleBack = () => {
    if (router.canGoBack()) {
      router.back();
      return;
    }

    router.replace(backHref);
  };

  return (
    <View className="mb-5 flex-row items-center justify-between" style={{ gap: 12 }}>
      {showBack ? (
        <Pressable
          accessibilityRole="button"
          onPress={handleBack}
          className="flex-row items-center rounded-full border border-line bg-white px-4 py-3"
          style={{ gap: 6 }}
        >
          <ChevronLeft size={16} color="#111111" />
          <Text className="text-[14px] font-semibold text-soft-ink">Back</Text>
        </Pressable>
      ) : (
        <View className="w-[76px]" />
      )}

      <View className="flex-1 items-center">
        <Link href="/" asChild>
          <Pressable accessibilityRole="link">
            <CooksyLogo size="md" />
          </Pressable>
        </Link>
      </View>

      <View className="w-[76px]" />
    </View>
  );
};
