import { ScrollView, Text, View } from "react-native";
import { router } from "expo-router";
import { ArrowLeft } from "lucide-react-native";

import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { TertiaryButton } from "@/components/common/Buttons";

export default function TermsOfServiceScreen() {
  return (
    <ScreenContainer scroll={false}>
      <TertiaryButton onPress={() => router.back()} fullWidth={false}>
        <View className="flex-row items-center" style={{ gap: 8 }}>
          <ArrowLeft size={16} color="#262626" />
          <Text>Back</Text>
        </View>
      </TertiaryButton>
      
      <ScrollView contentContainerClassName="pb-10">
        <Text className="mb-2 mt-4 text-[28px] font-bold text-ink">Terms of Service</Text>
        <Text className="mb-6 text-[15px] text-muted">Last updated: April 2026</Text>
        
        <CooksyCard className="mb-4">
          <Text className="mb-4 text-[15px] leading-6 text-soft-ink">
            By using Cooksy, you agree to these Terms of Service. Please read them carefully. 
            If you do not agree to these terms, please do not use our service.
          </Text>
        </CooksyCard>

        <View style={{ gap: 20 }}>
          <Section title="1. Description of Service">
            <Text className="text-[15px] leading-6 text-soft-ink">
              Cooksy is a recipe management service that allows users to import cooking videos 
              from YouTube, TikTok, and Instagram, and convert them into structured recipes 
              for personal use.
            </Text>
          </Section>

          <Section title="2. User Accounts">
            <BulletPoint>You may use Cooksy with an anonymous account</BulletPoint>
            <BulletPoint>You are responsible for maintaining the security of your account</BulletPoint>
            <BulletPoint>You must be at least 13 years old to use this service</BulletPoint>
            <BulletPoint>You may not use the service for commercial purposes without permission</BulletPoint>
          </Section>

          <Section title="3. Acceptable Use">
            <Text className="mb-2 text-[15px] leading-6 text-soft-ink">You agree NOT to:</Text>
            <BulletPoint>Import content that violates copyright laws</BulletPoint>
            <BulletPoint>Use the service to scrape or download videos</BulletPoint>
            <BulletPoint>Attempt to circumvent rate limits or security measures</BulletPoint>
            <BulletPoint>Upload malicious code or attempt to breach the service</BulletPoint>
            <BulletPoint>Use the service for any illegal activities</BulletPoint>
            <BulletPoint>Import content that is hate speech, violent, or adult in nature</BulletPoint>
          </Section>

          <Section title="4. Content Ownership">
            <Text className="text-[15px] leading-6 text-soft-ink">
              You retain ownership of any original content you create in Cooksy (recipe edits, 
              collections, notes). However, imported recipe data is derived from third-party 
              sources and is subject to those platforms&apos; terms of service.
            </Text>
          </Section>

          <Section title="5. Service Limitations">
            <BulletPoint>Recipe extraction accuracy may vary by platform</BulletPoint>
            <BulletPoint>Import speed depends on source platform availability</BulletPoint>
            <BulletPoint>Rate limits apply: 8 imports per 15-minute window</BulletPoint>
            <BulletPoint>We do not guarantee recipe accuracy or food safety</BulletPoint>
          </Section>

          <Section title="6. Termination">
            <Text className="text-[15px] leading-6 text-soft-ink">
              We reserve the right to suspend or terminate accounts that violate these terms 
              or engage in abusive behavior. You may delete your account at any time, 
              which will remove all associated data.
            </Text>
          </Section>

          <Section title="7. Disclaimer of Warranty">
            <Text className="text-[15px] leading-6 text-soft-ink">
              THE SERVICE IS PROVIDED &quot;AS IS&quot; WITHOUT WARRANTIES OF ANY KIND, 
              EITHER EXPRESS OR IMPLIED. WE DO NOT GUARANTEE RECIPE ACCURACY, 
              COMPLETENESS, OR FOOD SAFETY.
            </Text>
          </Section>

          <Section title="8. Limitation of Liability">
            <Text className="text-[15px] leading-6 text-soft-ink">
              IN NO EVENT SHALL COOKSY BE LIABLE FOR ANY INDIRECT, INCIDENTAL, 
              SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE 
              OF THE SERVICE.
            </Text>
          </Section>

          <Section title="9. Changes to Terms">
            <Text className="text-[15px] leading-6 text-soft-ink">
              We may update these terms from time to time. We will notify users of 
              significant changes via the app or email. Continued use after changes 
              constitutes acceptance of the new terms.
            </Text>
          </Section>

          <Section title="10. Contact Information">
            <Text className="text-[15px] leading-6 text-soft-ink">
              For questions about these Terms of Service, contact us at:
              legal@cooksy.app
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
