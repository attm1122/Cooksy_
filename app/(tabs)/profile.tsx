import { Link } from "expo-router";
import { FileText, MoonStar, Scale, ShieldCheck, UserRound } from "lucide-react-native";
import { Text, View } from "react-native";

import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";

type RouteHref = "/legal/privacy" | "/legal/terms" | null;

const settingRows: Array<{
  title: string;
  subtitle: string;
  icon: typeof UserRound;
  href: RouteHref;
}> = [
  { title: "Account", subtitle: "Profile and sign-in settings", icon: UserRound, href: null },
  { title: "Appearance", subtitle: "Theme controls and display preferences", icon: MoonStar, href: null },
  { title: "Privacy", subtitle: "Import history and saved recipe permissions", icon: ShieldCheck, href: "/legal/privacy" }
];

const legalRows: Array<{
  title: string;
  subtitle: string;
  icon: typeof UserRound;
  href: "/legal/privacy" | "/legal/terms";
}> = [
  { title: "Privacy Policy", subtitle: "How we handle your data", icon: ShieldCheck, href: "/legal/privacy" },
  { title: "Terms of Service", subtitle: "Rules for using Cooksy", icon: FileText, href: "/legal/terms" },
  { title: "Content Policy", subtitle: "What content is allowed", icon: Scale, href: "/legal/terms" }
];

export default function ProfileScreen() {
  return (
    <ScreenContainer>
      <Text className="mb-2 text-[28px] font-bold text-ink">Profile & settings</Text>
      <Text className="mb-5 text-[15px] leading-6 text-muted">
        Manage your account, preferences, and legal information.
      </Text>

      <View style={{ gap: 12 }}>
        {settingRows.map((row) => {
          const Icon = row.icon;
          const CardContent = (
            <CooksyCard className="p-4">
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

          if (row.href) {
            return (
              <Link key={row.title} href={row.href} asChild>
                <View>{CardContent}</View>
              </Link>
            );
          }

          return <View key={row.title}>{CardContent}</View>;
        })}
      </View>

      <Text className="mb-3 mt-6 text-[20px] font-bold text-ink">Legal</Text>
      <View style={{ gap: 12 }}>
        {legalRows.map((row) => {
          const Icon = row.icon;
          return (
            <Link key={row.title} href={row.href} asChild>
              <View>
                <CooksyCard className="p-4">
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
              </View>
            </Link>
          );
        })}
      </View>
    </ScreenContainer>
  );
}
