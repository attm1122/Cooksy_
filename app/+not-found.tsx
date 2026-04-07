import { Link, usePathname } from "expo-router";
import { Pressable, Text, View } from "react-native";

export default function NotFoundScreen() {
  const pathname = usePathname();

  return (
    <View style={{ flex: 1, backgroundColor: "#FFFDF7", alignItems: "center", justifyContent: "center", padding: 32 }}>
      <View
        style={{
          width: 72,
          height: 72,
          borderRadius: 20,
          backgroundColor: "#F5EDD6",
          alignItems: "center",
          justifyContent: "center",
          marginBottom: 24
        }}
      >
        <Text style={{ fontSize: 36 }}>🍳</Text>
      </View>

      <Text
        style={{
          fontSize: 28,
          fontWeight: "800",
          color: "#1A1A1A",
          textAlign: "center",
          marginBottom: 10
        }}
      >
        Page not found
      </Text>

      <Text
        style={{
          fontSize: 16,
          color: "#6B6B5E",
          textAlign: "center",
          lineHeight: 24,
          marginBottom: 36,
          maxWidth: 320
        }}
      >
        The page you're looking for doesn't exist or has moved.
      </Text>

      <Link href="/" asChild>
        <Pressable
          style={({ pressed }) => ({
            backgroundColor: "#C4A96A",
            paddingHorizontal: 28,
            paddingVertical: 14,
            borderRadius: 14,
            opacity: pressed ? 0.85 : 1,
            marginBottom: 14
          })}
        >
          <Text style={{ color: "#1A1A1A", fontWeight: "700", fontSize: 16 }}>Go home</Text>
        </Pressable>
      </Link>
    </View>
  );
}
