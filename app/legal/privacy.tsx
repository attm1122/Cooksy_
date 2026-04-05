import { ScrollView, Text, View } from "react-native";
import { router } from "expo-router";
import { ArrowLeft } from "lucide-react-native";

import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { TertiaryButton } from "@/components/common/Buttons";

export default function PrivacyPolicyScreen() {
  return (
    <ScreenContainer scroll={false}>
      <TertiaryButton onPress={() => router.back()} fullWidth={false}>
        <View className="flex-row items-center" style={{ gap: 8 }}>
          <ArrowLeft size={16} color="#262626" />
          <Text>Back</Text>
        </View>
      </TertiaryButton>
      
      <ScrollView contentContainerClassName="pb-10">
        <Text className="mb-2 mt-4 text-[28px] font-bold text-ink">Privacy Policy</Text>
        <Text className="mb-6 text-[15px] text-muted">Last updated: April 2026</Text>
        
        <CooksyCard className="mb-4">
          <Text className="mb-4 text-[15px] leading-6 text-soft-ink">
            Cooksy (&quot;we&quot;, &quot;our&quot;, or &quot;us&quot;) is committed to protecting your privacy. 
            This Privacy Policy explains how we collect, use, and safeguard your information 
            when you use our recipe import and management service.
          </Text>
        </CooksyCard>

        <View style={{ gap: 20 }}>
          <Section title="1. Information We Collect">
            <BulletPoint>Recipe URLs you submit for import</BulletPoint>
            <BulletPoint>Recipe data extracted from video sources</BulletPoint>
            <BulletPoint>Recipe edits and customizations you make</BulletPoint>
            <BulletPoint>Recipe books and collections you create</BulletPoint>
            <BulletPoint>Anonymous usage analytics</BulletPoint>
          </Section>

          <Section title="2. How We Use Your Information">
            <BulletPoint>To process and convert video recipes into structured formats</BulletPoint>
            <BulletPoint>To save and organize your recipe collection</BulletPoint>
            <BulletPoint>To improve our recipe extraction algorithms</BulletPoint>
            <BulletPoint>To provide customer support</BulletPoint>
          </Section>

          <Section title="3. Data Storage & Security">
            <Text className="text-[15px] leading-6 text-soft-ink">
              Your data is stored securely using Supabase, with encryption at rest and in transit. 
              We use Row Level Security (RLS) to ensure you can only access your own data. 
              Recipe data is retained for as long as you maintain an account.
            </Text>
          </Section>

          <Section title="4. Third-Party Services">
            <Text className="text-[15px] leading-6 text-soft-ink">
              We use the following third-party services:
            </Text>
            <BulletPoint>Supabase - Database and authentication</BulletPoint>
            <BulletPoint>YouTube, TikTok, Instagram APIs - Recipe extraction</BulletPoint>
            <BulletPoint>PostHog - Anonymous analytics</BulletPoint>
          </Section>

          <Section title="5. Your Rights (GDPR/CCPA)">
            <BulletPoint>Access your personal data</BulletPoint>
            <BulletPoint>Request data deletion</BulletPoint>
            <BulletPoint>Export your data</BulletPoint>
            <BulletPoint>Opt-out of analytics</BulletPoint>
          </Section>

          <Section title="6. Data Retention">
            <Text className="text-[15px] leading-6 text-soft-ink">
              Recipe data is retained until you delete it or close your account. 
              Anonymous analytics data is retained for 90 days. 
              Import job logs are retained for 30 days.
            </Text>
          </Section>

          <Section title="7. Contact Us">
            <Text className="text-[15px] leading-6 text-soft-ink">
              For privacy-related questions or to exercise your rights, contact us at:
              privacy@cooksy.app
            </Text>
          </Section>
        </View>
      </ScrollView>
    </ScreenContainer>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <View>
      <Text className="mb-2 text-[20px] font-bold text-ink">{title}</Text>
      {children}
    </View>
  );
}

function BulletPoint({ children }: { children: React.ReactNode }) {
  return (
    <View className="flex-row" style={{ gap: 8 }}>
      <Text className="text-[15px] text-soft-ink">•</Text>
      <Text className="flex-1 text-[15px] leading-6 text-soft-ink">{children}</Text>
    </View>
  );
}
