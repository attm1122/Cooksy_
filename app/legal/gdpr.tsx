import { router } from "expo-router";
import { ArrowLeft, Download, Trash2 } from "lucide-react-native";
import { useState } from "react";
import { Alert, ScrollView, Text, View } from "react-native";

import { PrimaryButton, SecondaryButton, TertiaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { captureError } from "@/lib/monitoring";
import { supabase } from "@/lib/supabase";

export default function GDPRScreen() {
  const [exporting, setExporting] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const handleExportData = async () => {
    setExporting(true);
    try {
      if (!supabase) {
        Alert.alert("Error", "Supabase not configured");
        return;
      }

      const { data: user } = await supabase.auth.getUser();
      if (!user.user) {
        Alert.alert("Error", "You must be logged in to export data");
        return;
      }

      const { data, error } = await supabase.rpc("export_user_data", {
        p_user_id: user.user.id
      });

      if (error) throw error;

      // In a real app, you'd email this or provide a download link
      // For now, we just log it
      console.log("User data export:", JSON.stringify(data, null, 2));
      
      Alert.alert(
        "Data Export Ready",
        "Your data export has been prepared. In a production app, this would be emailed to you or available for download."
      );
    } catch (error) {
      captureError(error, { action: "export_user_data" });
      Alert.alert("Error", "Failed to export data");
    } finally {
      setExporting(false);
    }
  };

  const handleDeleteAccount = () => {
    Alert.alert(
      "Delete Account",
      "This will permanently delete all your recipes, books, and data. This action cannot be undone.",
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete",
          style: "destructive",
          onPress: async () => {
            setDeleting(true);
            try {
              if (!supabase) {
                Alert.alert("Error", "Supabase not configured");
                return;
              }

              const { data: user } = await supabase.auth.getUser();
              if (!user.user) {
                Alert.alert("Error", "You must be logged in");
                return;
              }

              const { data, error } = await supabase.rpc("delete_user_account", {
                p_user_id: user.user.id
              });

              if (error) throw error;

              Alert.alert(
                "Account Deleted",
                `Deleted ${data.deleted.recipes} recipes, ${data.deleted.books} books, and ${data.deleted.jobs} import jobs.`
              );

              // Sign out and redirect
              await supabase.auth.signOut();
              router.replace("/home" as never);
            } catch (error) {
              captureError(error, { action: "delete_user_account" });
              Alert.alert("Error", "Failed to delete account");
            } finally {
              setDeleting(false);
            }
          }
        }
      ]
    );
  };

  return (
    <ScreenContainer scroll={false}>
      <TertiaryButton onPress={() => router.back()} fullWidth={false}>
        <View className="flex-row items-center" style={{ gap: 8 }}>
          <ArrowLeft size={16} color="#262626" />
          <Text>Back</Text>
        </View>
      </TertiaryButton>
      
      <ScrollView contentContainerClassName="pb-10">
        <Text className="mb-2 mt-4 text-[28px] font-bold text-ink">Your Data & Privacy</Text>
        <Text className="mb-6 text-[15px] text-muted">
          Manage your personal data and privacy settings.
        </Text>

        <View style={{ gap: 16 }}>
          <CooksyCard>
            <Text className="mb-2 text-[20px] font-bold text-ink">Export Your Data</Text>
            <Text className="mb-4 text-[15px] leading-6 text-soft-ink">
              Download a copy of all your data, including recipes, books, and account information. 
              This is your right under GDPR (Right to Data Portability).
            </Text>
            <PrimaryButton 
              onPress={handleExportData} 
              loading={exporting}
            >
              <View className="flex-row items-center" style={{ gap: 8 }}>
                <Download size={16} color="#111111" />
                <Text className="text-[15px] font-semibold text-ink">Export My Data</Text>
              </View>
            </PrimaryButton>
          </CooksyCard>

          <CooksyCard>
            <Text className="mb-2 text-[20px] font-bold text-ink">Delete Your Account</Text>
            <Text className="mb-4 text-[15px] leading-6 text-soft-ink">
              Permanently delete your account and all associated data. This includes:
            </Text>
            <View className="mb-4" style={{ gap: 8 }}>
              <BulletPoint>All saved recipes</BulletPoint>
              <BulletPoint>Recipe books and collections</BulletPoint>
              <BulletPoint>Import history</BulletPoint>
              <BulletPoint>Account information</BulletPoint>
            </View>
            <Text className="mb-4 text-[15px] leading-6 text-danger">
              This action cannot be undone. This is your right under GDPR (Right to be Forgotten).
            </Text>
            <SecondaryButton 
              onPress={handleDeleteAccount}
              loading={deleting}
            >
              <View className="flex-row items-center" style={{ gap: 8 }}>
                <Trash2 size={16} color="#262626" />
                <Text className="text-[15px] font-semibold text-soft-ink">Delete My Account</Text>
              </View>
            </SecondaryButton>
          </CooksyCard>

          <CooksyCard>
            <Text className="mb-2 text-[20px] font-bold text-ink">Your Rights</Text>
            <Text className="mb-4 text-[15px] leading-6 text-soft-ink">
              Under GDPR and similar privacy laws, you have the following rights:
            </Text>
            <View style={{ gap: 12 }}>
              <RightItem 
                title="Right to Access" 
                description="You can request a copy of all data we hold about you."
              />
              <RightItem 
                title="Right to Rectification" 
                description="You can correct inaccurate or incomplete data."
              />
              <RightItem 
                title="Right to Erasure" 
                description="You can request deletion of your personal data."
              />
              <RightItem 
                title="Right to Portability" 
                description="You can receive your data in a structured format."
              />
              <RightItem 
                title="Right to Object" 
                description="You can object to certain types of processing."
              />
            </View>
          </CooksyCard>

          <CooksyCard>
            <Text className="mb-2 text-[20px] font-bold text-ink">Contact Us</Text>
            <Text className="mb-4 text-[15px] leading-6 text-soft-ink">
              If you have any questions about your data or privacy rights, contact us at:
            </Text>
            <Text className="text-[15px] font-semibold text-soft-ink">
              privacy@cooksy.app
            </Text>
          </CooksyCard>
        </View>
      </ScrollView>
    </ScreenContainer>
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

function RightItem({ title, description }: { title: string; description: string }) {
  return (
    <View>
      <Text className="text-[16px] font-semibold text-ink">{title}</Text>
      <Text className="text-[14px] text-muted">{description}</Text>
    </View>
  );
}
