import { MoonStar, ShieldCheck, UserRound } from "lucide-react-native";
import { Text, View } from "react-native";

import { AppHeader } from "@/components/common/AppHeader";
import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";

const rows = [
  { title: "Account", subtitle: "Profile and sign-in settings", icon: UserRound },
  { title: "Appearance", subtitle: "Theme controls and display preferences", icon: MoonStar },
  { title: "Privacy", subtitle: "Import history and saved recipe permissions", icon: ShieldCheck }
];

export default function ProfileScreen() {
  return (
    <ScreenContainer>
      <AppHeader />
      <Text className="mb-2 text-[28px] font-bold text-ink">Profile & settings</Text>
      <Text className="mb-5 text-[15px] leading-6 text-muted">
        A lightweight shell for the MVP, with room for accounts, sync, and preferences.
      </Text>

      <View style={{ gap: 12 }}>
        {rows.map((row) => {
          const Icon = row.icon;

          return (
            <CooksyCard key={row.title} className="p-4">
              <View className="flex-row items-center" style={{ gap: 14 }}>
                <View className="h-11 w-11 items-center justify-center rounded-full bg-brand-yellow-soft">
                  <Icon size={18} color="#111111" />
                </View>
                <View className="flex-1">
                  <Text className="text-[16px] font-bold text-ink">{row.title}</Text>
                  <Text className="text-[14px] text-muted">{row.subtitle}</Text>
                </View>
              </View>
            </CooksyCard>
          );
        })}
      </View>
    </ScreenContainer>
  );
}
