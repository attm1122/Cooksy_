import { Link } from "expo-router";
import { Crown, FileText, MoonStar, Scale, ShieldCheck, UserRound } from "lucide-react-native";
import { Text, View } from "react-native";

import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { PremiumBadge } from "@/components/subscription/PremiumBadge";
import { useIsPremium } from "@/stores/subscription-store";

type RouteHref = "/legal/privacy" | "/legal/terms" | "/subscription/manage" | null;

export default function ProfileScreen() {
  const isPremium = useIsPremium();

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

  return (
    <ScreenContainer>
      <View className="flex-row items-center justify-between mb-2">
        <Text className="text-[28px] font-bold text-ink">Profile & settings</Text>
        <PremiumBadge />
      </View>
      <Text className="mb-5 text-[15px] leading-6 text-muted">
        Manage your account, preferences, and legal information.
      </Text>

      {/* Subscription Section */}
      <Text className="mb-3 text-[20px] font-bold text-ink">Subscription</Text>
      <View style={{ gap: 12 }} className="mb-6">
        <Link href={"/subscription/manage" as never} asChild>
          <View>
            <CooksyCard className="p-4">
              <View className="flex-row items-center" style={{ gap: 14 }}>
                <View className={`h-11 w-11 items-center justify-center rounded-full ${isPremium ? 'bg-amber-100' : 'bg-brand-yellow-soft'}`}>
                  <Crown size={18} color={isPremium ? '#F59E0B' : '#111111'} />
                </View>
                <View className="flex-1">
                  <Text className="text-[16px] font-bold text-ink">
                    {isPremium ? 'Premium Active' : 'Go Premium'}
                  </Text>
                  <Text className="text-[14px] text-muted">
                    {isPremium ? 'Manage your subscription' : 'Unlock unlimited features'}
                  </Text>
                </View>
              </View>
            </CooksyCard>
          </View>
        </Link>
      </View>

      <Text className="mb-3 text-[20px] font-bold text-ink">Settings</Text>
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
              <Link key={row.title} href={row.href as never} asChild>
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
            <Link key={row.title} href={row.href as never} asChild>
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
