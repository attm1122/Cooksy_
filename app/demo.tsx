import { Link } from "expo-router";
import { Platform, ScrollView, Text, View, Pressable, Image } from "react-native";

const DEMO_RECIPES = [
  {
    id: "1",
    title: "Creamy Garlic Chicken Bowl",
    creator: "@mealsbymiri",
    platform: "TikTok",
    confidence: 87,
    time: "28 min",
    tags: ["Weeknight", "High protein"],
    image: "https://cooksy-six.vercel.app/assets/assets/landing/bowl.0dce7e03c527051f3f4c4f9e9d07b65e.jpg",
    bg: "#C4A96A",
    inferredNote: "Garlic amount was inferred from transcript and visible ingredient list."
  },
  {
    id: "2",
    title: "Spiced Paneer with Crispy Chickpeas",
    creator: "@plantbasedkitchen",
    platform: "Instagram",
    confidence: 92,
    time: "35 min",
    tags: ["Vegetarian", "Meal prep"],
    image: "https://cooksy-six.vercel.app/assets/assets/landing/spiced-paneer.0dce7e03c527051f3f4c4f9e9d07b65e.jpg",
    bg: "#D4895A",
    inferredNote: "Spice quantities confirmed from on-screen text and recipe card in video."
  },
  {
    id: "3",
    title: "Loaded Smash Burger Fries",
    creator: "@burgerlab",
    platform: "YouTube",
    confidence: 79,
    time: "22 min",
    tags: ["Comfort", "Weekend"],
    image: "https://cooksy-six.vercel.app/assets/assets/landing/cheese-fries.74671c17c496956b3e99306afbf494c0.jpg",
    bg: "#B85C38",
    inferredNote: "Cooking time estimated from video duration. Check visually when fries are golden."
  }
];

function ConfidenceDot({ score }: { score: number }) {
  const color = score >= 85 ? "#4CAF7D" : score >= 70 ? "#C4A96A" : "#D4895A";
  return (
    <View style={{ flexDirection: "row", alignItems: "center", gap: 5 }}>
      <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: color }} />
      <Text style={{ fontSize: 13, color: "#6B6B5E", fontWeight: "500" }}>{score}% confidence</Text>
    </View>
  );
}

function RecipeCard({ recipe }: { recipe: typeof DEMO_RECIPES[0] }) {
  return (
    <View
      style={{
        backgroundColor: "#FFFFFF",
        borderRadius: 20,
        borderWidth: 1,
        borderColor: "#E8E3D8",
        marginBottom: 16,
        overflow: "hidden",
        shadowColor: "#000",
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.06,
        shadowRadius: 8
      }}
    >
      <View style={{ height: 180, backgroundColor: recipe.bg, justifyContent: "flex-end", padding: 16 }}>
        <View style={{ flexDirection: "row", gap: 6 }}>
          {recipe.tags.map((tag) => (
            <View key={tag} style={{ backgroundColor: "rgba(255,255,255,0.25)", borderRadius: 6, paddingHorizontal: 8, paddingVertical: 3 }}>
              <Text style={{ color: "#fff", fontSize: 12, fontWeight: "600" }}>{tag}</Text>
            </View>
          ))}
        </View>
      </View>
      <View style={{ padding: 18 }}>
        <Text style={{ fontSize: 18, fontWeight: "700", color: "#1A1A1A", marginBottom: 6 }}>{recipe.title}</Text>
        <View style={{ flexDirection: "row", alignItems: "center", gap: 10, marginBottom: 12 }}>
          <Text style={{ fontSize: 13, color: "#6B6B5E" }}>{recipe.creator}</Text>
          <Text style={{ fontSize: 13, color: "#C4D1CC" }}>·</Text>
          <Text style={{ fontSize: 13, color: "#6B6B5E" }}>{recipe.platform}</Text>
          <Text style={{ fontSize: 13, color: "#C4D1CC" }}>·</Text>
          <Text style={{ fontSize: 13, color: "#6B6B5E" }}>{recipe.time}</Text>
        </View>
        <ConfidenceDot score={recipe.confidence} />
        <View
          style={{
            marginTop: 12,
            backgroundColor: "#F7F5EF",
            borderRadius: 10,
            padding: 12,
            borderLeftWidth: 3,
            borderLeftColor: "#C4A96A"
          }}
        >
          <Text style={{ fontSize: 12, color: "#6B6B5E", lineHeight: 18 }}>
            <Text style={{ fontWeight: "600", color: "#4A4A3E" }}>Cooksy note: </Text>
            {recipe.inferredNote}
          </Text>
        </View>
      </View>
    </View>
  );
}

export default function DemoScreen() {
  const isWeb = Platform.OS === "web";

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: "#FFFDF7" }}
      contentContainerStyle={{
        paddingHorizontal: isWeb ? Math.max(16, 0) : 16,
        paddingTop: 60,
        paddingBottom: 80,
        maxWidth: isWeb ? 680 : undefined,
        alignSelf: isWeb ? "center" : undefined,
        width: "100%"
      }}
    >
      <Link href="/" asChild>
        <Pressable style={{ marginBottom: 28 }}>
          <Text style={{ fontSize: 14, color: "#C4A96A", fontWeight: "600" }}>← Back to Cooksy</Text>
        </Pressable>
      </Link>

      <Text style={{ fontSize: 13, fontWeight: "600", color: "#C4A96A", letterSpacing: 1, marginBottom: 8, textTransform: "uppercase" }}>
        How it works
      </Text>
      <Text style={{ fontSize: 30, fontWeight: "800", color: "#1A1A1A", lineHeight: 36, marginBottom: 10 }}>
        From saved video to cookable recipe
      </Text>
      <Text style={{ fontSize: 16, color: "#6B6B5E", lineHeight: 24, marginBottom: 32 }}>
        These are real recipes as Cooksy surfaces them — with ingredients, confidence scores, and notes on what was inferred.
      </Text>

      {DEMO_RECIPES.map((recipe) => (
        <RecipeCard key={recipe.id} recipe={recipe} />
      ))}

      <View
        style={{
          backgroundColor: "#1A1A1A",
          borderRadius: 20,
          padding: 28,
          alignItems: "center",
          marginTop: 8
        }}
      >
        <Text style={{ fontSize: 22, fontWeight: "700", color: "#FFFDF7", marginBottom: 8, textAlign: "center" }}>
          Save food videos you'll actually cook
        </Text>
        <Text style={{ fontSize: 15, color: "#9B9B8E", marginBottom: 20, textAlign: "center", lineHeight: 22 }}>
          Import from TikTok, Instagram, or YouTube. Cooksy turns them into structured recipes in the background.
        </Text>
        <Link href="/auth" asChild>
          <Pressable
            style={({ pressed }) => ({
              backgroundColor: "#C4A96A",
              paddingHorizontal: 28,
              paddingVertical: 14,
              borderRadius: 12,
              opacity: pressed ? 0.85 : 1
            })}
          >
            <Text style={{ color: "#1A1A1A", fontWeight: "700", fontSize: 16 }}>Create profile free</Text>
          </Pressable>
        </Link>
      </View>
    </ScrollView>
  );
}
