import { useEffect, useState } from "react";
import { Alert, Linking, Text, View } from "react-native";
import { useRouter } from "expo-router";
import {
  Calendar,
  Check,
  ChevronRight,
  CreditCard,
  Crown,
  ExternalLink,
  HelpCircle,
  RefreshCcw,
  Sparkles,
  X,
} from "lucide-react-native";

import { PrimaryButton, SecondaryButton, TertiaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { captureError } from "@/lib/monitoring";
import {
  getManagementURL,
  restorePurchases,
} from "@/lib/subscription";
import {
  selectCurrentPlan,
  selectIsPremium,
  selectWillRenew,
  useSubscriptionStore,
} from "@/stores/subscription-store";

function formatExpiryDate(dateString: string | null): string {
  if (!dateString) return "N/A";
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

function FeatureRow({ text, included }: { text: string; included: boolean }) {
  return (
    <View className="flex-row items-center" style={{ gap: 12 }}>
      <View
        className={`h-6 w-6 items-center justify-center rounded-full ${included ? "bg-brand-yellow" : "bg-surface-alt"}`}
      >
        {included ? (
          <Check size={13} color="#111111" />
        ) : (
          <X size={12} color="#9A9A90" />
        )}
      </View>
      <Text className={`flex-1 text-[15px] ${included ? "text-soft-ink" : "text-muted"}`}>{text}</Text>
    </View>
  );
}

function ActionRow({
  icon: Icon,
  label,
  onPress,
}: {
  icon: typeof ExternalLink;
  label: string;
  onPress: () => void;
}) {
  return (
    <TertiaryButton onPress={onPress} fullWidth>
      <View className="flex-row items-center justify-between px-1">
        <View className="flex-row items-center" style={{ gap: 12 }}>
          <Icon size={18} color="#262626" />
          <Text className="text-[15px] font-semibold text-soft-ink">{label}</Text>
        </View>
        <ChevronRight size={16} color="#9A9A90" />
      </View>
    </TertiaryButton>
  );
}

export default function SubscriptionManagementScreen() {
  const router = useRouter();
  const [refreshing, setRefreshing] = useState(false);
  const [managementUrl, setManagementUrl] = useState<string | null>(null);

  const isPremium = useSubscriptionStore(selectIsPremium);
  const currentPlan = useSubscriptionStore(selectCurrentPlan);
  const willRenew = useSubscriptionStore(selectWillRenew);
  const store = useSubscriptionStore();

  useEffect(() => {
    let active = true;
    void getManagementURL().then((url) => {
      if (active) setManagementUrl(url);
    });
    return () => {
      active = false;
    };
  }, []);

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      await store.refresh();
    } catch (error) {
      captureError(error, { action: "subscription_refresh" });
    } finally {
      setRefreshing(false);
    }
  };

  const handleRestore = async () => {
    const result = await restorePurchases();
    if (result.success && result.isPremium) {
      Alert.alert("Restored", "Your Premium subscription is back.");
    } else if (result.success) {
      Alert.alert("Nothing found", "No previous purchases were found for this account.");
    } else {
      Alert.alert("Could not restore", result.error ?? "Something went wrong. Try again.");
    }
  };

  const handleManage = () => {
    if (managementUrl) {
      void Linking.openURL(managementUrl);
    } else {
      Alert.alert(
        "Manage subscription",
        "Open the App Store or Play Store settings on your device to manage your subscription.",
      );
    }
  };

  const handleSupport = () => {
    void Linking.openURL("mailto:support@cooksy.app?subject=Subscription%20Support");
  };

  if (!isPremium) {
    return (
      <ScreenContainer>
        <View className="mb-6 items-center py-6">
          <View className="mb-4 h-16 w-16 items-center justify-center rounded-[22px] bg-surface-alt">
            <Crown size={32} color="#9A9A90" />
          </View>
          <Text className="text-[28px] font-bold text-ink">Free plan</Text>
          <Text className="mt-2 text-center text-[15px] leading-6 text-muted">
            You have access to the basics. Upgrade to unlock unlimited imports and every feature Cooksy has.
          </Text>
        </View>

        <CooksyCard className="mb-4">
          <Text className="mb-4 text-[13px] font-semibold uppercase tracking-[1px] text-muted">Your plan includes</Text>
          <View style={{ gap: 14 }}>
            <FeatureRow text="5 recipe imports per month (YouTube)" included />
            <FeatureRow text="Basic recipe library" included />
            <FeatureRow text="Recipe books" included={false} />
            <FeatureRow text="TikTok & Instagram imports" included={false} />
            <FeatureRow text="Delete recipes" included={false} />
            <FeatureRow text="Unlimited imports" included={false} />
          </View>
        </CooksyCard>

        <CooksyCard className="mb-6 border-brand-yellow">
          <View className="mb-3 flex-row items-center" style={{ gap: 10 }}>
            <Sparkles size={18} color="#111111" />
            <Text className="text-[18px] font-bold text-ink">Cooksy Premium</Text>
          </View>
          <View style={{ gap: 14 }}>
            <FeatureRow text="Unlimited imports from any platform" included />
            <FeatureRow text="Recipe books & collections" included />
            <FeatureRow text="Delete and edit recipes" included />
            <FeatureRow text="Priority processing" included />
          </View>
          <View className="mt-5">
            <PrimaryButton onPress={() => router.push("/subscription/paywall" as never)}>
              Upgrade to Premium
            </PrimaryButton>
          </View>
        </CooksyCard>

        <SecondaryButton onPress={handleRestore}>Restore Purchases</SecondaryButton>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer>
      <View className="mb-6 items-center py-6">
        <View className="mb-4 h-16 w-16 items-center justify-center rounded-[22px] bg-brand-yellow-soft">
          <Crown size={32} color="#111111" />
        </View>
        <Text className="text-[28px] font-bold text-ink">Premium active</Text>
        <Text className="mt-1 text-[15px] capitalize text-muted">
          {currentPlan ?? "Monthly"} plan
        </Text>
      </View>

      <CooksyCard className="mb-4">
        <Text className="mb-4 text-[13px] font-semibold uppercase tracking-[1px] text-muted">Subscription details</Text>
        <View style={{ gap: 16 }}>
          <View className="flex-row items-center justify-between">
            <View className="flex-row items-center" style={{ gap: 10 }}>
              <CreditCard size={16} color="#6B655C" />
              <Text className="text-[15px] text-soft-ink">Plan</Text>
            </View>
            <Text className="text-[15px] font-semibold capitalize text-ink">
              {currentPlan ?? "Monthly"}
            </Text>
          </View>
          <View className="h-px bg-line" />
          <View className="flex-row items-center justify-between">
            <View className="flex-row items-center" style={{ gap: 10 }}>
              <Calendar size={16} color="#6B655C" />
              <Text className="text-[15px] text-soft-ink">
                {willRenew ? "Renews on" : "Expires on"}
              </Text>
            </View>
            <Text className="text-[15px] font-semibold text-ink">
              {formatExpiryDate(store.expiresDate)}
            </Text>
          </View>
          <View className="h-px bg-line" />
          <View className="flex-row items-center justify-between">
            <View className="flex-row items-center" style={{ gap: 10 }}>
              <RefreshCcw size={16} color="#6B655C" />
              <Text className="text-[15px] text-soft-ink">Auto-renew</Text>
            </View>
            <View
              className={`rounded-full px-3 py-1 ${willRenew ? "bg-[#EEF9F2]" : "bg-[#FFF1EE]"}`}
            >
              <Text
                className={`text-[13px] font-semibold ${willRenew ? "text-[#1D6B45]" : "text-[#8F4A1D]"}`}
              >
                {willRenew ? "On" : "Off"}
              </Text>
            </View>
          </View>
        </View>
      </CooksyCard>

      <CooksyCard className="mb-4">
        <Text className="mb-4 text-[13px] font-semibold uppercase tracking-[1px] text-muted">Premium benefits</Text>
        <View style={{ gap: 14 }}>
          <FeatureRow text="Unlimited imports from any platform" included />
          <FeatureRow text="Recipe books & collections" included />
          <FeatureRow text="Delete and edit recipes" included />
          <FeatureRow text="Priority processing" included />
        </View>
      </CooksyCard>

      <CooksyCard className="mb-6">
        <Text className="mb-3 text-[13px] font-semibold uppercase tracking-[1px] text-muted">Actions</Text>
        <View style={{ gap: 8 }}>
          <ActionRow icon={ExternalLink} label="Manage subscription" onPress={handleManage} />
          <ActionRow icon={RefreshCcw} label="Restore purchases" onPress={handleRestore} />
          <ActionRow icon={HelpCircle} label="Contact support" onPress={handleSupport} />
        </View>
      </CooksyCard>

      <TertiaryButton onPress={handleRefresh} disabled={refreshing}>
        {refreshing ? "Refreshing…" : "Refresh subscription status"}
      </TertiaryButton>
    </ScreenContainer>
  );
}
