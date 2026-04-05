import { Link } from "expo-router";
import { ArrowRight, CheckCircle2, Clock3, Library, PlayCircle, ShoppingBag, Sparkles, Wand2 } from "lucide-react-native";
import { Pressable, ScrollView, Text, View, useWindowDimensions } from "react-native";
import { LinearGradient } from "expo-linear-gradient";

import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { CooksyLogo } from "@/components/common/CooksyLogo";

const heroSignals = [
  "Paste TikTok, Instagram, or YouTube links",
  "Get ingredients, steps, timing, and grocery list in one pass",
  "Fix uncertain details fast before you cook"
] as const;

const journeyCards = [
  {
    label: "01 Import",
    title: "Save the recipe the second you see it",
    body: "Cooksy saves first, then reconstructs in the background so the product feels instant instead of demanding your attention."
  },
  {
    label: "02 Review",
    title: "See where confidence is strong or soft",
    body: "Estimated values and uncertain steps are visible, which makes the result feel honest and easy to improve."
  },
  {
    label: "03 Cook",
    title: "Move into grocery mode or guided cooking",
    body: "The product is built to get you from inspiration to action, not just leave you with another saved link."
  }
] as const;

const premiumFeatures = [
  {
    icon: PlayCircle,
    title: "Fast import pipeline",
    body: "Social cooking videos become structured recipes with source context, timing, and a clean cooking format."
  },
  {
    icon: Wand2,
    title: "Trust-first recipe reconstruction",
    body: "Confidence, evidence, and easy correction are part of the product surface instead of hidden system details."
  },
  {
    icon: ShoppingBag,
    title: "Grocery list in one tap",
    body: "A recipe becomes usable immediately, which is the whole point of saving it in the first place."
  },
  {
    icon: Library,
    title: "A visual library that still feels alive",
    body: "Thumbnails, source context, and calm organization keep recipes tied to the food content that inspired them."
  }
] as const;

const productStats = [
  { value: "3", label: "supported source platforms" },
  { value: "1 tap", label: "to turn a recipe into a grocery list" },
  { value: "step-by-step", label: "cooking mode for real kitchen use" }
] as const;

const faqs = [
  {
    question: "Is Cooksy replacing the original creator?",
    answer:
      "No. Cooksy keeps source attribution visible and uses the original content as the starting point for a recipe you can actually cook from."
  },
  {
    question: "What if a video leaves out quantities or timings?",
    answer:
      "Cooksy surfaces what was inferred, lowers confidence where needed, and gives you a fast fix path so the result stays usable and trustworthy."
  },
  {
    question: "Why not just save the link in a notes app?",
    answer:
      "Because the hard part is not storing the link. The hard part is turning it into something structured enough to shop, edit, and cook from."
  }
] as const;

const SectionPill = ({
  children,
  tone = "light"
}: {
  children: string;
  tone?: "light" | "dark";
}) => (
  <View
    className={`self-start rounded-full px-4 py-2 ${tone === "dark" ? "bg-[#1A1A1A]" : "bg-white"}`}
    style={{
      borderWidth: 1,
      borderColor: tone === "dark" ? "#2D2D2D" : "#DCD5C8",
      shadowColor: "#111111",
      shadowOpacity: tone === "dark" ? 0 : 0.04,
      shadowRadius: 8,
      shadowOffset: { width: 0, height: 2 }
    }}
  >
    <Text className={`text-[12px] font-semibold uppercase tracking-[1px] ${tone === "dark" ? "text-white" : "text-soft-ink"}`}>
      {children}
    </Text>
  </View>
);

const HeroDevice = () => (
  <View className="relative min-h-[560px] flex-1 overflow-hidden rounded-[38px] bg-[#E7FF2D] px-7 py-7">
    <LinearGradient
      colors={["rgba(255, 253, 247, 0.7)", "rgba(255, 253, 247, 0)", "rgba(17, 17, 17, 0.08)"]}
      className="absolute inset-0"
    />

    <View className="absolute left-7 top-7 rounded-[26px] bg-white/92 px-4 py-4">
      <Text className="text-[12px] font-semibold uppercase tracking-[0.8px] text-muted">Latest import</Text>
      <Text className="mt-2 text-[30px] font-bold text-ink">91%</Text>
      <Text className="text-[12px] text-[#277A49]">High confidence reconstruction</Text>
    </View>

    <View className="absolute bottom-7 left-7 rounded-[24px] bg-[#111111] px-4 py-4">
      <Text className="text-[12px] font-semibold uppercase tracking-[0.8px] text-white/60">Cooking mode</Text>
      <Text className="mt-2 max-w-[210px] text-[15px] leading-7 text-white">
        One calm step at a time, with timings and the grocery checklist already handled.
      </Text>
    </View>

    <View className="absolute right-7 top-28 rounded-[24px] bg-[#FFF8D7] px-4 py-4">
      <Text className="text-[12px] font-semibold uppercase tracking-[0.8px] text-muted">Ready next</Text>
      <Text className="mt-2 text-[16px] font-bold text-ink">Open grocery list</Text>
      <View className="mt-3 flex-row items-center" style={{ gap: 8 }}>
        <ShoppingBag size={16} color="#111111" />
        <Text className="text-[13px] text-soft-ink">11 ingredients checked</Text>
      </View>
    </View>

    <View
      className="mx-auto mt-16 w-full max-w-[340px] rounded-[42px] border border-[#1B1B1B] bg-[#181818] px-4 pb-5 pt-4"
      style={{
        shadowColor: "#111111",
        shadowOpacity: 0.2,
        shadowRadius: 24,
        shadowOffset: { width: 0, height: 12 }
      }}
    >
      <View className="mb-4 flex-row items-center justify-between">
        <View className="h-2 w-16 rounded-full bg-[#353535]" />
        <Text className="text-[11px] font-semibold text-white/70">Cooksy</Text>
      </View>

      <View className="overflow-hidden rounded-[30px] bg-[#232323]">
        <View className="h-[200px] bg-[#D99B57] px-4 py-4">
          <LinearGradient
            colors={["rgba(17, 17, 17, 0.04)", "rgba(17, 17, 17, 0.38)"]}
            className="absolute inset-0"
          />
          <View className="mt-auto">
            <Text className="text-[12px] font-semibold uppercase tracking-[0.8px] text-white/70">YouTube import</Text>
            <Text className="mt-2 text-[28px] font-bold leading-[32px] text-white">Crispy hot honey salmon</Text>
            <Text className="mt-2 text-[13px] text-white/75">2 servings • 14 min • Fixes available</Text>
          </View>
        </View>

        <View className="px-4 py-4">
          <View className="mb-3 flex-row items-center justify-between">
            <Text className="text-[13px] font-semibold text-white/65">Reconstructed recipe</Text>
            <View className="rounded-full bg-white/7 px-3 py-1">
              <Text className="text-[11px] font-semibold uppercase tracking-[0.8px] text-white/70">Grocery ready</Text>
            </View>
          </View>

          <View style={{ gap: 10 }}>
            {[
              "1.5 lb salmon fillet",
              "2 tbsp hot honey glaze",
              "Roast until the center just turns flaky",
              "Finish with lemon, herbs, and crispy edges"
            ].map((line) => (
              <View key={line} className="flex-row items-center rounded-[18px] bg-white/7 px-3 py-3" style={{ gap: 10 }}>
                <CheckCircle2 size={16} color="#F5C400" />
                <Text className="flex-1 text-[13px] leading-6 text-white/88">{line}</Text>
              </View>
            ))}
          </View>
        </View>
      </View>
    </View>
  </View>
);

export const WebLandingPage = () => {
  const { width } = useWindowDimensions();
  const isDesktop = width >= 1120;
  const isTablet = width >= 760;

  return (
    <LinearGradient colors={["#C3C79D", "#D7D0BD", "#ECE5D7"]} className="flex-1">
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 20 }}>
        <View
          className="mx-auto w-full overflow-hidden rounded-[42px] bg-[#F8F4EC] px-5 pb-14 pt-5"
          style={{
            maxWidth: 1220,
            shadowColor: "#111111",
            shadowOpacity: 0.1,
            shadowRadius: 32,
            shadowOffset: { width: 0, height: 16 }
          }}
        >
          <View className="mb-7 flex-row items-center justify-between rounded-[28px] bg-white px-5 py-4">
            <CooksyLogo size="md" />
            <View className="flex-row items-center" style={{ gap: 12 }}>
              {isTablet ? (
                <>
                  <Text className="text-[14px] font-semibold text-soft-ink">Import</Text>
                  <Text className="text-[14px] font-semibold text-soft-ink">Fix</Text>
                  <Text className="text-[14px] font-semibold text-soft-ink">Cook</Text>
                </>
              ) : null}
              <Link href={"/home" as never} asChild>
                <Pressable className="rounded-full bg-ink px-5 py-3">
                  <Text className="text-[14px] font-semibold text-white">Open app</Text>
                </Pressable>
              </Link>
            </View>
          </View>

          <View
            className="mb-7"
            style={{
              flexDirection: isDesktop ? "row" : "column",
              gap: 18
            }}
          >
            <View className="min-h-[560px] flex-1 rounded-[38px] bg-white px-7 py-8">
              <SectionPill>Cooksy for web</SectionPill>

              <Text className="mt-7 max-w-[560px] text-[58px] font-bold leading-[60px] text-ink">
                Save the food you discover and actually cook it later.
              </Text>

              <Text className="mt-5 max-w-[520px] text-[18px] leading-8 text-muted">
                Cooksy turns social cooking videos into structured recipes with source context, confidence cues, grocery lists, and a cleaner path from inspiration to dinner.
              </Text>

              <View className="mt-9" style={{ gap: 12 }}>
                {heroSignals.map((signal) => (
                  <View key={signal} className="flex-row items-start" style={{ gap: 10 }}>
                    <CheckCircle2 size={18} color="#111111" style={{ marginTop: 3 }} />
                    <Text className="flex-1 text-[15px] leading-7 text-soft-ink">{signal}</Text>
                  </View>
                ))}
              </View>

              <View className="mt-9 flex-row flex-wrap" style={{ gap: 12 }}>
                <Link href={"/home" as never} asChild>
                  <View>
                    <PrimaryButton fullWidth={false}>
                      <View className="flex-row items-center" style={{ gap: 8 }}>
                        <Text className="text-[15px] font-semibold text-ink">Start on web</Text>
                        <ArrowRight size={16} color="#111111" />
                      </View>
                    </PrimaryButton>
                  </View>
                </Link>

                <Link href="/recipes" asChild>
                  <View>
                    <SecondaryButton fullWidth={false}>
                      <Text className="text-[15px] font-semibold text-soft-ink">See the product</Text>
                    </SecondaryButton>
                  </View>
                </Link>
              </View>

              <View className="mt-10 flex-row flex-wrap" style={{ gap: 12 }}>
                {["Web app", "iPhone", "Android"].map((label) => (
                  <View key={label} className="rounded-full border border-line bg-[#FBF8F1] px-4 py-3">
                    <Text className="text-[13px] font-semibold text-soft-ink">{label}</Text>
                  </View>
                ))}
              </View>
            </View>

            <HeroDevice />
          </View>

          <View
            className="mb-16 rounded-[34px] bg-[#111111] px-6 py-6"
            style={{
              flexDirection: isDesktop ? "row" : "column",
              gap: 14
            }}
          >
            {productStats.map((stat, index) => (
              <View
                key={stat.label}
                className={`rounded-[26px] px-5 py-5 ${isDesktop ? "flex-1" : ""}`}
                style={{
                  backgroundColor: index === 1 ? "#E7FF2D" : "#1E1E1E",
                  borderWidth: 1,
                  borderColor: index === 1 ? "#E7FF2D" : "#2A2A2A"
                }}
              >
                <Text className={`text-[30px] font-bold ${index === 1 ? "text-ink" : "text-white"}`}>{stat.value}</Text>
                <Text className={`mt-2 text-[14px] leading-7 ${index === 1 ? "text-soft-ink" : "text-white/72"}`}>{stat.label}</Text>
              </View>
            ))}
          </View>

          <View className="mb-16 items-center px-3">
            <SectionPill>Why it works</SectionPill>
            <Text className="mt-5 max-w-[800px] text-center text-[50px] font-bold leading-[54px] text-ink">
              The product is opinionated about what happens after the save.
            </Text>
            <Text className="mt-4 max-w-[720px] text-center text-[17px] leading-8 text-muted">
              Cooksy is not just a place to store links. It is built to turn social recipe content into something you can review, shop from, and cook without friction.
            </Text>
          </View>

          <View className="mb-16 flex-row flex-wrap" style={{ gap: 16 }}>
            {journeyCards.map((card) => (
              <CooksyCard key={card.title} className={`${isDesktop ? "flex-1" : "w-full"} p-6`}>
                <SectionPill>{card.label}</SectionPill>
                <Text className="mt-6 text-[32px] font-bold leading-[38px] text-ink">{card.title}</Text>
                <Text className="mt-4 text-[15px] leading-7 text-muted">{card.body}</Text>
              </CooksyCard>
            ))}
          </View>

          <View
            className="mb-16 rounded-[38px] bg-white px-6 py-8"
            style={{ gap: 24 }}
          >
            <View
              style={{
                flexDirection: isDesktop ? "row" : "column",
                justifyContent: "space-between",
                gap: 18
              }}
            >
              <View className="max-w-[640px]">
                <SectionPill>Premium details</SectionPill>
                <Text className="mt-5 text-[46px] font-bold leading-[50px] text-ink">
                  A calmer, higher-trust cooking product
                </Text>
              </View>
              <Text className="max-w-[360px] text-[15px] leading-7 text-muted">
                The visual system stays warm and quiet, while the product surfaces what matters most: the recipe, the source, the confidence, and the next action.
              </Text>
            </View>

            <View className="flex-row flex-wrap" style={{ gap: 16 }}>
              {premiumFeatures.map((feature, index) => {
                const Icon = feature.icon;
                const accent = index === 1;
                return (
                  <View
                    key={feature.title}
                    className={`${isDesktop ? "flex-1" : "w-full"} rounded-[30px] px-5 py-6`}
                    style={{
                      backgroundColor: accent ? "#E7FF2D" : "#F8F4EC",
                      borderWidth: 1,
                      borderColor: accent ? "#D7EA5B" : "#E8E0D3"
                    }}
                  >
                    <View className="mb-6 h-12 w-12 items-center justify-center rounded-full bg-white">
                      <Icon size={18} color="#111111" />
                    </View>
                    <Text className="text-[25px] font-bold leading-[31px] text-ink">{feature.title}</Text>
                    <Text className="mt-3 text-[14px] leading-7 text-soft-ink">{feature.body}</Text>
                  </View>
                );
              })}
            </View>
          </View>

          <View
            className="mb-16"
            style={{
              flexDirection: isDesktop ? "row" : "column",
              gap: 18
            }}
          >
            <View className="flex-1 rounded-[36px] bg-[#D1D4B3] px-6 py-7">
              <SectionPill>Inside the product</SectionPill>
              <Text className="mt-5 text-[44px] font-bold leading-[48px] text-ink">
                Thumbnail first. Structured second. Always ready for action.
              </Text>
              <Text className="mt-4 max-w-[470px] text-[15px] leading-7 text-soft-ink">
                Cooksy keeps the emotional connection of the original food content, then adds the structure needed to actually make the dish.
              </Text>
            </View>

            <View className="flex-1 rounded-[36px] bg-white px-6 py-7">
              <View className="rounded-[28px] bg-[#FAF7EF] p-5">
                <Text className="text-[13px] font-semibold uppercase tracking-[0.9px] text-muted">First five minutes</Text>
                <View className="mt-5" style={{ gap: 14 }}>
                  {[
                    { icon: PlayCircle, text: "Import from a social recipe link" },
                    { icon: Sparkles, text: "Review confidence and fix uncertain fields" },
                    { icon: ShoppingBag, text: "Generate your grocery list" },
                    { icon: Clock3, text: "Cook one step at a time" }
                  ].map((item) => {
                    const Icon = item.icon;
                    return (
                      <View key={item.text} className="flex-row items-start" style={{ gap: 10 }}>
                        <Icon size={16} color="#111111" style={{ marginTop: 4 }} />
                        <Text className="flex-1 text-[15px] leading-7 text-soft-ink">{item.text}</Text>
                      </View>
                    );
                  })}
                </View>
              </View>
            </View>
          </View>

          <View className="items-center px-3">
            <SectionPill>FAQ</SectionPill>
            <Text className="mt-5 max-w-[780px] text-center text-[46px] font-bold leading-[50px] text-ink">
              Questions people ask before they trust a recipe product
            </Text>
          </View>

          <View className="mt-8" style={{ gap: 12 }}>
            {faqs.map((faq, index) => (
              <View key={faq.question} className="rounded-[28px] border border-line bg-white px-5 py-5">
                <View className="flex-row items-start" style={{ gap: 12 }}>
                  <Text className="w-8 text-[13px] font-bold text-muted">{String(index + 1).padStart(2, "0")}</Text>
                  <View className="flex-1">
                    <Text className="text-[22px] font-bold leading-[28px] text-ink">{faq.question}</Text>
                    <Text className="mt-3 text-[15px] leading-7 text-muted">{faq.answer}</Text>
                  </View>
                </View>
              </View>
            ))}
          </View>
        </View>
      </ScrollView>
    </LinearGradient>
  );
};
