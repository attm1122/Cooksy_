import AsyncStorage from "@react-native-async-storage/async-storage";
import { Link } from "expo-router";
import { useEffect, useState } from "react";
import { Platform, Pressable, Text, View } from "react-native";

const CONSENT_KEY = "cooksy_cookie_consent_v1";

export function CookieConsent() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (Platform.OS !== "web") return;
    AsyncStorage.getItem(CONSENT_KEY).then((value) => {
      if (!value) {
        setVisible(true);
      }
    });
  }, []);

  const handleAccept = async () => {
    await AsyncStorage.setItem(CONSENT_KEY, "accepted");
    setVisible(false);
  };

  const handleDecline = async () => {
    await AsyncStorage.setItem(CONSENT_KEY, "declined");
    setVisible(false);
  };

  if (!visible || Platform.OS !== "web") return null;

  return (
    <View
      style={{
        position: "fixed" as never,
        bottom: 0,
        left: 0,
        right: 0,
        zIndex: 9999,
        backgroundColor: "#1A1A1A",
        borderTopWidth: 1,
        borderTopColor: "#2E2E2E",
        paddingHorizontal: 24,
        paddingVertical: 16,
        flexDirection: "row",
        alignItems: "center",
        flexWrap: "wrap",
        gap: 12
      }}
    >
      <Text style={{ color: "#E8E3D8", fontSize: 14, lineHeight: 20, flex: 1, minWidth: 240 }}>
        Cooksy uses cookies and analytics to improve your experience.{" "}
        <Link href="/legal/privacy" asChild>
          <Text style={{ color: "#C4A96A", textDecorationLine: "underline" }}>Privacy Policy</Text>
        </Link>
      </Text>
      <View style={{ flexDirection: "row", gap: 8 }}>
        <Pressable
          onPress={handleDecline}
          style={({ pressed }) => ({
            paddingHorizontal: 16,
            paddingVertical: 8,
            borderRadius: 8,
            borderWidth: 1,
            borderColor: "#3E3E3E",
            opacity: pressed ? 0.7 : 1
          })}
        >
          <Text style={{ color: "#9B9B8E", fontSize: 14, fontWeight: "500" }}>Decline</Text>
        </Pressable>
        <Pressable
          onPress={handleAccept}
          style={({ pressed }) => ({
            paddingHorizontal: 16,
            paddingVertical: 8,
            borderRadius: 8,
            backgroundColor: "#C4A96A",
            opacity: pressed ? 0.85 : 1
          })}
        >
          <Text style={{ color: "#1A1A1A", fontSize: 14, fontWeight: "600" }}>Accept</Text>
        </Pressable>
      </View>
    </View>
  );
}
