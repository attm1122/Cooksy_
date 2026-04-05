import { Link } from "expo-router";
import { ArrowRight, CheckCircle2, Library, PlayCircle, ShoppingBag, Sparkles, Wand2 } from "lucide-react-native";
import { useMemo } from "react";
import { Pressable, ScrollView, Text, View, useWindowDimensions } from "react-native";
import { LinearGradient } from "expo-linear-gradient";

import { CooksyLogo } from "@/components/common/CooksyLogo";
import { CooksyCard } from "@/components/common/CooksyCard";
import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";

const proofPoints = [
  "Paste TikTok, Instagram, or YouTube links",
  "Get ingredients, steps, timing, and confidence notes",
  "Fix anything fast, then cook from a clean step-by-step view"
] as const;

const productSteps = [
  {
    label: "Import",
    title: "Save a recipe the second you discover it",
    body: "Cooksy captures the link immediately, keeps the thumbnail-first vibe, and starts reconstructing the recipe in the background."
  },
  {
    label: "Fix",
    title: "See what was inferred and correct it quickly",
    body: "Low-confidence ingredients and steps are easy to review, so the recipe feels trustworthy instead of mysteriously generated."
  },
  {
    label: "Cook",
    title: "Move from inspiration to action",
    body: "Open grocery mode, step into cooking mode, and actually make the dish instead of losing it in a pile of saved videos."
  }
] as const;

const featureCards = [
  {
    icon: PlayCircle,
    title: "Link-to-recipe import",
    body: "Structured ingredients, steps, servings, and estimated time from social cooking content."
  },
  {
    icon: Wand2,
    title: "Trust layer built in",
    body: "Confidence notes, evidence summaries, and fast editing make the result feel usable, not magical in the wrong way."
  },
  {
    icon: ShoppingBag,
    title: "Grocery list in one tap",
    body: "Turn the recipe into a practical shopping checklist without leaving the flow."
  },
  {
    icon: Library,
    title: "Library that stays visual",
    body: "Original thumbnails, clear source context, and a calm recipe library that feels like saved food content."
  }
] as const;

const faqs = [
  {
    question: "Does Cooksy replace the original creator?",
    answer:
      "No. Cooksy keeps source attribution visible and uses the original content as the starting point for a recipe you can actually cook from."
  },
  {
    question: "What happens when recipe details are unclear?",
    answer:
      "Cooksy marks inferred and missing fields, lowers confidence appropriately, and makes it easy to fix uncertain ingredients or steps."
  },
  {
    question: "Is this web only?",
    answer:
      "No. Cooksy is one shared product across web, iOS, and Android, with the web experience acting as the cleanest entry point and preview surface."
  }
] as const;

const LandingPill = ({ children }: { children: string }) => (
  <View
    className="self-start rounded-full border border-[#D8D1C2] bg-white px-4 py-2"
    style={{ shadowColor: "#111111", shadowOpacity: 0.04, shadowRadius: 8, shadowOffset: { width: 0, height: 2 } }}
  >
    <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-soft-ink">{children}</Text>
  </View>
);

const HeroPhone = () => (
  <View className="relative min-h-[420px] flex-1 items-center justify-center rounded-[34px] bg-[#E6FF2F] px-6 py-8">
    <View className="absolute left-6 top-6 rounded-[24px] bg-white/90 px-4 py-3">
      <Text className="text-[12px] font-semibold text-muted">Latest import</Text>
      <Text className="mt-1 text-[28px] font-bold text-ink">92%</Text>
      <Text className="text-[12px] text-[#3A9B52]">High confidence</Text>
    </View>

    <View className="w-full max-w-[310px] rounded-[38px] border border-[#1A1A1A] bg-[#171717] px-4 pb-5 pt-4">
      <View className="mb-4 flex-row items-center justify-between">
        <View className="h-2 w-14 rounded-full bg-[#343434]" />
        <Text className="text-[11px] font-semibold text-white/70">Cooksy</Text>
      </View>
      <View className="rounded-[28px] bg-[#222222] px-4 py-4">
        <Text className="text-[13px] font-semibold text-white/70">Crispy hot honey salmon</Text>
        <Text className="mt-2 text-[34px] font-bold text-white">14 min</Text>
        <Text className="mt-1 text-[13px] text-white/65">2 servings • Grocery list ready</Text>

        <View className="mt-5" style={{ gap: 10 }}>
          {["1.5 lb salmon", "2 tbsp hot honey glaze", "Roast 8 minutes, then broil", "Finish with lemon and herbs"].map((line) => (
            <View key={line} className="flex-row items-center rounded-[18px] bg-white/7 px-3 py-3" style={{ gap: 10 }}>
              <CheckCircle2 size={16} color="#F5C400" />
              <Text className="flex-1 text-[13px] text-white/88">{line}</Text>
            </View>
          ))}
        </View>
      </View>
      <View className="mt-4 flex-row items-center justify-between rounded-[24px] bg-[#FBFBF0] px-4 py-3">
        <Text className="text-[13px] font-semibold text-ink">Open grocery list</Text>
        <ArrowRight size={16} color="#111111" />
      </View>
    </View>

    <View className="absolute bottom-6 right-6 rounded-full bg-white px-4 py-3">
      <Text className="text-[12px] font-semibold uppercase tracking-[0.8px] text-soft-ink">Built for real cooking</Text>
    </View>
  </View>
);

export const WebLandingPage = () => {
  const { width } = useWindowDimensions();
  const isWide = width >= 1040;
  const isMedium = width >= 760;
  const heroDirection = useMemo(() => (isWide ? "row" : "column"), [isWide]);

  return (
    <LinearGradient colors={["#C8CCA4", "#D7D4B9", "#E8E2D0"]} className="flex-1">
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 20 }}>
        <View
          className="mx-auto w-full rounded-[40px] bg-[#F8F5EE] px-5 pb-12 pt-5"
          style={{
            maxWidth: 1180,
            shadowColor: "#111111",
            shadowOpacity: 0.08,
            shadowRadius: 30,
            shadowOffset: { width: 0, height: 12 }
          }}
        >
          <View className="mb-6 flex-row items-center justify-between rounded-[26px] bg-white px-5 py-4">
            <CooksyLogo size="md" />
            <View className="flex-row items-center" style={{ gap: 12 }}>
              {isMedium ? (
                <>
                  <Text className="text-[14px] font-semibold text-soft-ink">Link to recipe</Text>
                  <Text className="text-[14px] font-semibold text-soft-ink">Fix with confidence</Text>
                  <Text className="text-[14px] font-semibold text-soft-ink">Cook anywhere</Text>
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
            className="mb-16"
            style={{
              flexDirection: heroDirection,
              gap: 18
            }}
          >
            <View className="min-h-[420px] flex-1 rounded-[34px] bg-white px-7 py-8">
              <LandingPill>Cooksy web</LandingPill>
              <Text className="mt-7 max-w-[520px] text-[54px] font-bold leading-[58px] text-ink">
                Save the food you discover and actually cook it.
              </Text>
              <Text className="mt-5 max-w-[500px] text-[18px] leading-8 text-muted">
                Cooksy turns social cooking videos into structured, editable recipes with thumbnails, grocery lists, and guided cooking built in.
              </Text>

              <View className="mt-8" style={{ gap: 12 }}>
                {proofPoints.map((point) => (
                  <View key={point} className="flex-row items-start" style={{ gap: 10 }}>
                    <CheckCircle2 size={18} color="#111111" style={{ marginTop: 2 }} />
                    <Text className="flex-1 text-[15px] leading-7 text-soft-ink">{point}</Text>
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
                      <Text className="text-[15px] font-semibold text-soft-ink">Explore the product</Text>
                    </SecondaryButton>
                  </View>
                </Link>
              </View>

              <View className="mt-9 flex-row flex-wrap" style={{ gap: 12 }}>
                {["Web app", "iPhone", "Android"].map((label) => (
                  <View key={label} className="rounded-full border border-line bg-[#FBF8F1] px-4 py-3">
                    <Text className="text-[13px] font-semibold text-soft-ink">{label}</Text>
                  </View>
                ))}
              </View>
            </View>

            <HeroPhone />
          </View>

          <View className="mb-16 items-center px-3">
            <LandingPill>How it works</LandingPill>
            <Text className="mt-5 max-w-[760px] text-center text-[48px] font-bold leading-[52px] text-ink">
              A shortcut between food inspiration and action
            </Text>
            <Text className="mt-4 max-w-[680px] text-center text-[17px] leading-8 text-muted">
              Cooksy is designed to make saved food content usable fast, without turning the experience into a chat product or a messy recipe database.
            </Text>
          </View>

          <View className="mb-16 flex-row flex-wrap" style={{ gap: 16 }}>
            {productSteps.map((step, index) => (
              <CooksyCard key={step.title} className={`${isWide ? "flex-1" : "w-full"} p-6`}>
                <LandingPill>{`${String(index + 1).padStart(2, "0")} ${step.label}`}</LandingPill>
                <Text className="mt-6 text-[30px] font-bold leading-[36px] text-ink">{step.title}</Text>
                <Text className="mt-4 text-[15px] leading-7 text-muted">{step.body}</Text>
              </CooksyCard>
            ))}
          </View>

          <View
            className="mb-16 rounded-[36px] bg-white px-6 py-8"
            style={{ gap: 20 }}
          >
            <View className="flex-row flex-wrap items-end justify-between" style={{ gap: 18 }}>
              <View className="max-w-[620px]">
                <LandingPill>Why it feels different</LandingPill>
                <Text className="mt-5 text-[44px] font-bold leading-[48px] text-ink">
                  Built for trust, not just extraction
                </Text>
              </View>
              <Text className="max-w-[360px] text-[15px] leading-7 text-muted">
                The product stays visual, shows what was inferred, and gives the user a fast fix path instead of pretending the recipe is perfect.
              </Text>
            </View>

            <View className="flex-row flex-wrap" style={{ gap: 16 }}>
              {featureCards.map((card, index) => {
                const Icon = card.icon;
                const highlighted = index === 1;
                return (
                  <View
                    key={card.title}
                    className={`${isWide ? "flex-1" : "w-full"} rounded-[28px] px-5 py-6`}
                    style={{
                      minWidth: isWide ? 0 : undefined,
                      backgroundColor: highlighted ? "#E6FF2F" : "#F8F5EE",
                      borderWidth: 1,
                      borderColor: highlighted ? "#D8E36C" : "#ECE3D3"
                    }}
                  >
                    <View className="mb-6 h-11 w-11 items-center justify-center rounded-full bg-white">
                      <Icon size={18} color="#111111" />
                    </View>
                    <Text className="text-[24px] font-bold leading-[30px] text-ink">{card.title}</Text>
                    <Text className="mt-3 text-[14px] leading-7 text-soft-ink">{card.body}</Text>
                  </View>
                );
              })}
            </View>
          </View>

          <View
            className="mb-16"
            style={{
              flexDirection: isWide ? "row" : "column",
              gap: 18
            }}
          >
            <View className="flex-1 rounded-[34px] bg-[#D0D1B6] px-6 py-7">
              <LandingPill>Inside the product</LandingPill>
              <Text className="mt-5 text-[42px] font-bold leading-[46px] text-ink">
                Thumbnail first. Structured second. Ready to cook.
              </Text>
              <Text className="mt-4 max-w-[460px] text-[15px] leading-7 text-soft-ink">
                The web landing page sets the tone, but the actual product keeps the same priorities: fast import, visible confidence, clean editing, and a calm cooking flow.
              </Text>
            </View>

            <View className="flex-1 rounded-[34px] bg-white px-6 py-7">
              <View className="rounded-[28px] bg-[#FAF7EF] p-5">
                <Text className="text-[13px] font-semibold uppercase tracking-[0.9px] text-muted">Core loop</Text>
                <View className="mt-5" style={{ gap: 14 }}>
                  {[
                    "Import a link from TikTok, Instagram, or YouTube",
                    "Review confidence and edit anything uncertain",
                    "Generate your grocery list",
                    "Cook one step at a time"
                  ].map((item) => (
                    <View key={item} className="flex-row items-start" style={{ gap: 10 }}>
                      <Sparkles size={16} color="#111111" style={{ marginTop: 4 }} />
                      <Text className="flex-1 text-[15px] leading-7 text-soft-ink">{item}</Text>
                    </View>
                  ))}
                </View>
              </View>
            </View>
          </View>

          <View className="items-center px-3">
            <LandingPill>FAQ</LandingPill>
            <Text className="mt-5 max-w-[760px] text-center text-[44px] font-bold leading-[48px] text-ink">
              Questions people ask before they trust a recipe app
            </Text>
          </View>

          <View className="mt-8" style={{ gap: 12 }}>
            {faqs.map((item, index) => (
              <View
                key={item.question}
                className="rounded-[28px] border border-line bg-white px-5 py-5"
              >
                <View className="flex-row items-start" style={{ gap: 12 }}>
                  <Text className="w-8 text-[13px] font-bold text-muted">{String(index + 1).padStart(2, "0")}</Text>
                  <View className="flex-1">
                    <Text className="text-[22px] font-bold leading-[28px] text-ink">{item.question}</Text>
                    <Text className="mt-3 text-[15px] leading-7 text-muted">{item.answer}</Text>
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
