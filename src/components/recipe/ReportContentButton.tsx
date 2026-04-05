import { AlertTriangle } from "lucide-react-native";
import { useState } from "react";
import { Alert, Modal, Pressable, Text, TextInput, View } from "react-native";

import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { reportContent } from "@/lib/moderation";
import { useCooksyStore } from "@/store/use-cooksy-store";

type ReportContentButtonProps = {
  recipeId: string;
};

const REPORT_REASONS = [
  "Inappropriate content",
  "Copyright violation",
  "Not a recipe",
  "Incorrect information",
  "Spam",
  "Other"
];

export const ReportContentButton = ({ recipeId }: ReportContentButtonProps) => {
  const [modalVisible, setModalVisible] = useState(false);
  const [selectedReason, setSelectedReason] = useState<string>("");
  const [details, setDetails] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const userId = useCooksyStore((state) => state.recipes.find(r => r.id === recipeId)?.id);

  const handleReport = async () => {
    if (!selectedReason) {
      Alert.alert("Please select a reason");
      return;
    }

    setSubmitting(true);
    const result = await reportContent({
      recipeId,
      reason: selectedReason,
      details: details || undefined,
      reporterUserId: undefined // Anonymous for now
    });
    setSubmitting(false);

    if (result.success) {
      setModalVisible(false);
      setSelectedReason("");
      setDetails("");
      Alert.alert(
        "Report Submitted",
        "Thank you for helping keep Cooksy safe. We'll review this content."
      );
    } else {
      Alert.alert("Error", result.error || "Failed to submit report");
    }
  };

  return (
    <>
      <Pressable
        onPress={() => setModalVisible(true)}
        className="flex-row items-center rounded-full bg-[#FFF1E8] px-4 py-2"
        style={{ gap: 8 }}
      >
        <AlertTriangle size={16} color="#8F4A1D" />
        <Text className="text-[13px] font-semibold text-[#8F4A1D]">Report</Text>
      </Pressable>

      <Modal
        animationType="slide"
        transparent={true}
        visible={modalVisible}
        onRequestClose={() => setModalVisible(false)}
      >
        <View className="flex-1 justify-end bg-black/50">
          <CooksyCard className="m-4 max-h-[80%]">
            <View className="p-4">
              <Text className="mb-1 text-[22px] font-bold text-ink">Report Content</Text>
              <Text className="mb-4 text-[14px] text-muted">
                Help us keep Cooksy safe by reporting content that violates our guidelines.
              </Text>

              <Text className="mb-2 text-[15px] font-semibold text-ink">Why are you reporting this?</Text>
              <View className="mb-4" style={{ gap: 8 }}>
                {REPORT_REASONS.map((reason) => (
                  <Pressable
                    key={reason}
                    onPress={() => setSelectedReason(reason)}
                    className={`rounded-[20px] border px-4 py-3 ${
                      selectedReason === reason
                        ? "border-brand-yellow bg-brand-yellow-soft"
                        : "border-line bg-white"
                    }`}
                  >
                    <Text className="text-[15px] text-soft-ink">{reason}</Text>
                  </Pressable>
                ))}
              </View>

              <Text className="mb-2 text-[15px] font-semibold text-ink">Additional details (optional)</Text>
              <TextInput
                value={details}
                onChangeText={setDetails}
                multiline
                numberOfLines={3}
                placeholder="Tell us more about the issue..."
                className="mb-4 rounded-[20px] border border-line bg-white px-4 py-3 text-[15px] text-soft-ink"
              />

              <View style={{ gap: 12 }}>
                <PrimaryButton onPress={handleReport} loading={submitting}>
                  Submit Report
                </PrimaryButton>
                <SecondaryButton onPress={() => setModalVisible(false)}>
                  Cancel
                </SecondaryButton>
              </View>
            </View>
          </CooksyCard>
        </View>
      </Modal>
    </>
  );
};
