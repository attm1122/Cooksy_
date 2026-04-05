import { Link } from "expo-router";
import { ArrowRight, CheckCircle2, Clock3, Library, PlayCircle, ShoppingBag, Sparkles, Wand2 } from "lucide-react-native";
import { Image, Pressable, ScrollView, Text, View, useWindowDimensions } from "react-native";
import { LinearGradient } from "expo-linear-gradient";

import { CooksyLogo } from "@/components/common/CooksyLogo";

const bowlImage = require("../../../assets/landing/bowl.jpg");
const friesImage = require("../../../assets/landing/cheese-fries.jpg");
const paneerImage = require("../../../assets/landing/spiced-paneer.jpg");

const navItems = ["Product", "Flow", "Trust", "FAQ"] as const;

const highlights = [
  "Turn TikTok, Instagram, and YouTube links into cookable recipes",
  "See what was inferred before you buy ingredients",
  "Go from saved post to grocery list in a few taps"
] as const;

const features = [
  {
    icon: PlayCircle,
    title: "Import in one tap",
    body: "Paste a food link and Cooksy saves it instantly, then turns it into a structured recipe in the background."
  },
  {
    icon: Wand2,
    title: "Trust what you're cooking",
    body: "Cooksy shows confidence, inferred fields, and source evidence so you can review a recipe before dinner depends on it."
  },
  {
    icon: ShoppingBag,
    title: "Shop faster",
    body: "Turn ingredients into a grocery list right away instead of rewatching a video while standing in the aisle."
  },
  {
    icon: Library,
    title: "Keep the recipes you'll actually make",
    body: "Your library stays visual, organized, and tied back to the creator or video that made you want to cook it."
  }
] as const;

const faqs = [
  {
    question: "Why is Cooksy different from saving links in notes?",
    answer:
      "Because the job is not storing the link. The job is turning it into something structured enough to shop, fix, and cook from."
  },
  {
    question: "What happens when the source leaves out details?",
    answer:
      "Cooksy marks what was inferred, lowers confidence where needed, and lets you correct ingredients or steps quickly."
  },
  {
    question: "Why would I pay for Cooksy instead of doing this manually?",
    answer:
      "Because manual recipe saving breaks at the exact point where you want to cook. Cooksy saves the time you lose rewatching, rewriting, estimating, and building a shopping list from scratch."
  },
  {
    question: "Does Cooksy keep creator attribution?",
    answer:
      "Yes. The original source remains visible so the recipe still feels connected to the creator and the content you discovered."
  }
] as const;

const softShadow = {
  shadowColor: "#101010",
  shadowOpacity: 0.06,
  shadowRadius: 24,
  shadowOffset: { width: 0, height: 8 }
} as const;

const pillStyle = {
  borderWidth: 1,
  borderColor: "#E9EAF0",
  backgroundColor: "#FFFFFF",
  shadowColor: "#101010",
  shadowOpacity: 0.04,
  shadowRadius: 16,
  shadowOffset: { width: 0, height: 6 }
} as const;

const SectionPill = ({ children }: { children: string }) => (
  <View className="self-start rounded-full px-4 py-2" style={pillStyle}>
    <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-soft-ink">{children}</Text>
  </View>
);

const NavLink = ({ label }: { label: string }) => (
  <Pressable className="px-2 py-2">
    <Text className="text-[14px] font-medium text-[#5E6270]">{label}</Text>
  </Pressable>
);

const FoodPhoto = ({
  source,
  height,
  rounded = 24,
  label,
  tone = "light"
}: {
  source: number;
  height: number;
  rounded?: number;
  label?: string;
  tone?: "light" | "dark";
}) => (
  <View className="relative overflow-hidden bg-[#F5F1E8]" style={{ height, borderRadius: rounded }}>
    <Image source={source} resizeMode="cover" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
    <LinearGradient
      colors={tone === "dark" ? ["rgba(17,17,17,0)", "rgba(17,17,17,0.5)"] : ["rgba(255,255,255,0)", "rgba(17,17,17,0.16)"]}
      start={{ x: 0.5, y: 0.1 }}
      end={{ x: 0.5, y: 1 }}
      className="absolute inset-x-0 bottom-0 h-[46%]"
    />
    {label ? (
      <View className="absolute left-4 top-4 rounded-full bg-white/90 px-3 py-2">
        <Text className="text-[11px] font-semibold uppercase tracking-[0.9px] text-ink">{label}</Text>
      </View>
    ) : null}
  </View>
);

const HeroDashboard = () => (
  <View className="relative min-h-[560px] flex-1 items-center justify-end overflow-hidden rounded-[36px] border border-[#E8EAF0] bg-white px-5 pb-7 pt-6">
    <View
      className="absolute inset-0"
      style={{
        borderTopLeftRadius: 36,
        borderTopRightRadius: 36,
        borderBottomLeftRadius: 36,
        borderBottomRightRadius: 36
      }}
    >
      <View className="absolute left-[10%] top-0 h-full w-[1px] bg-[#ECEEF5]" />
      <View className="absolute left-[52%] top-0 h-full w-[1px] bg-[#ECEEF5]" />
      <View className="absolute right-[10%] top-0 h-full w-[1px] bg-[#ECEEF5]" />
      <View className="absolute left-[28%] top-[26%] h-[160px] w-[1px] -rotate-45 bg-[#F0F2F8]" />
      <View className="absolute right-[24%] top-[24%] h-[180px] w-[1px] rotate-45 bg-[#F0F2F8]" />
      <LinearGradient
        colors={["rgba(255,246,204,0.1)", "rgba(245,196,0,0.28)", "rgba(255,244,163,0.08)"]}
        start={{ x: 0.1, y: 0 }}
        end={{ x: 0.9, y: 1 }}
        className="absolute inset-x-8 top-10 h-[260px] rounded-[36px]"
      />
    </View>

    <View className="absolute left-6 top-6 rounded-full px-4 py-2" style={pillStyle}>
      <Text className="text-[13px] font-medium text-[#4A7FEA]">Built for people who save food videos and actually want to cook them.</Text>
    </View>

    <View
      className="absolute left-2 bottom-16 w-[112px] rounded-[24px] border border-[#E8EEF8] bg-white px-3 py-3"
      style={[softShadow, { transform: [{ rotate: "-18deg" }] }]}
    >
      <Text className="text-[10px] font-semibold uppercase tracking-[0.8px] text-[#7A8192]">Import quality</Text>
      <Text className="mt-2 text-[24px] font-bold text-ink">+32%</Text>
      <Text className="mt-1 text-[11px] leading-5 text-[#6B7180]">Clearer ingredient extraction and stronger timing cues.</Text>
    </View>

    <View
      className="absolute right-4 bottom-20 w-[220px] rounded-[28px] border border-[#E8EEF8] bg-white px-4 py-4"
      style={[softShadow, { transform: [{ rotate: "8deg" }] }]}
    >
      <Text className="text-[13px] font-semibold text-ink">Cooksy note</Text>
      <Text className="mt-2 text-[14px] leading-7 text-[#5F6573]">
        Garlic amount was inferred from the transcript and visible ingredient list, so it stays easy to review.
      </Text>
    </View>

    <View className="absolute left-7 top-24 h-[184px] w-[138px] overflow-hidden rounded-[28px] border border-[#E8EAF0] bg-white" style={[softShadow, { transform: [{ rotate: "-10deg" }] }]}>
      <Image source={paneerImage} resizeMode="cover" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
    </View>

    <View className="absolute right-10 top-24 h-[160px] w-[132px] overflow-hidden rounded-[28px] border border-[#E8EAF0] bg-white" style={[softShadow, { transform: [{ rotate: "9deg" }] }]}>
      <Image source={friesImage} resizeMode="cover" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
    </View>

    <View
      className="w-full max-w-[620px] rounded-[30px] border border-[#E5EBF7] bg-white px-4 py-4"
      style={[
        softShadow,
        {
          shadowOpacity: 0.09,
          shadowRadius: 30
        }
      ]}
    >
      <View className="mb-4 flex-row items-center justify-between" style={{ gap: 16 }}>
        <View className="flex-1">
          <Text className="text-[15px] font-semibold text-ink">From saved post to grocery-ready recipe</Text>
          <Text className="mt-1 text-[13px] text-[#7A8192]">Keep the original visual, then layer in the structure needed to cook</Text>
        </View>
        <View className="rounded-full bg-[#FFF6CC] px-3 py-2">
          <Text className="text-[12px] font-semibold text-[#6E5700]">Faster than doing it yourself</Text>
        </View>
      </View>

      <View className="h-[268px] overflow-hidden rounded-[24px] bg-[#FCFDFF] px-4 py-4">
        <LinearGradient
          colors={["rgba(255,255,255,0)", "rgba(245,196,0,0.18)", "rgba(255,255,255,0)"]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          className="absolute inset-0"
        />

        <View className="flex-row" style={{ gap: 12 }}>
          <View className="h-[236px] flex-1 overflow-hidden rounded-[22px]">
            <Image source={bowlImage} resizeMode="cover" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            <LinearGradient
              colors={["rgba(17,17,17,0)", "rgba(17,17,17,0.72)"]}
              start={{ x: 0.5, y: 0.1 }}
              end={{ x: 0.5, y: 1 }}
              className="absolute inset-x-0 bottom-0 h-[110px]"
            />
            <View className="absolute inset-x-4 bottom-4">
              <Text className="text-[11px] font-semibold uppercase tracking-[1px] text-[#FFF3B3]">Imported recipe</Text>
              <Text className="mt-1 text-[22px] font-bold text-white">Creamy garlic chicken bowl</Text>
              <Text className="mt-1 text-[13px] text-white/80">Ingredients, timings, and confidence made usable before you shop.</Text>
            </View>
          </View>

          <View className="w-[190px]" style={{ gap: 12 }}>
            <View className="rounded-[20px] border border-[#E8EAF0] bg-white px-4 py-4">
              <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-[#7B8190]">Confidence</Text>
              <Text className="mt-3 text-[30px] font-bold text-ink">87%</Text>
              <Text className="mt-2 text-[13px] leading-6 text-[#68707F]">Strong signal match with only a few estimated quantities to review.</Text>
            </View>
            <View className="overflow-hidden rounded-[20px] border border-[#E8EAF0] bg-white">
              <Image source={paneerImage} resizeMode="cover" className="h-[112px] w-full" />
            </View>
          </View>
        </View>
      </View>
    </View>
  </View>
);

export const WebLandingPage = () => {
  const { width } = useWindowDimensions();
  const isDesktop = width >= 1140;
  const isTablet = width >= 760;

  return (
    <LinearGradient colors={["#FFFDF7", "#FDFBF2", "#F4F6FB"]} className="flex-1">
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 10 }}>
        <View
          className="mx-auto w-full overflow-hidden rounded-[34px] border border-[#E3E6EE] bg-[#FAFBFD] px-4 pb-14 pt-6"
          style={{ maxWidth: 1320 }}
        >
          <View className="relative overflow-hidden rounded-[30px] border border-[#E7EAF1] bg-[#FBFCFE] px-4 pb-12 pt-5">
            <View className="absolute inset-0">
              <View className="absolute left-[24%] top-0 h-full w-[1px] bg-[#EDEFF5]" />
              <View className="absolute left-[76%] top-0 h-full w-[1px] bg-[#EDEFF5]" />
              <LinearGradient
                colors={["rgba(245,196,0,0.16)", "rgba(255,255,255,0)"]}
                start={{ x: 0.15, y: 0 }}
                end={{ x: 0.8, y: 0.9 }}
                className="absolute left-[20%] top-8 h-[420px] w-[60%] rounded-[999px]"
              />
            </View>

            <View
              className="mx-auto mb-12 w-full max-w-[980px] flex-row items-center justify-between rounded-[26px] border border-[#E8EAF0] bg-white px-5 py-4"
              style={softShadow}
            >
              <CooksyLogo size="md" />
              {isTablet ? (
                <View className="flex-row items-center" style={{ gap: 22 }}>
                  {navItems.map((item) => (
                    <NavLink key={item} label={item} />
                  ))}
                </View>
              ) : <View />}
              <Link href={"/home" as never} asChild>
                <Pressable
                  className="rounded-full border border-[#23262E] bg-[#16181D] px-5 py-3"
                  style={{ shadowColor: "#16181D", shadowOpacity: 0.14, shadowRadius: 10, shadowOffset: { width: 0, height: 4 } }}
                >
                  <View className="flex-row items-center" style={{ gap: 8 }}>
                    <Text className="text-[13px] font-semibold uppercase tracking-[0.8px] text-white">Open app</Text>
                    <View className="h-6 w-6 items-center justify-center rounded-full bg-white">
                      <ArrowRight size={14} color="#111111" />
                    </View>
                  </View>
                </Pressable>
              </Link>
            </View>

            <View className="mb-16 items-center px-4">
              <SectionPill>Cooksy for web, iPhone, and Android</SectionPill>
              <Text className="mt-8 max-w-[920px] text-center text-[66px] font-bold leading-[70px] text-ink">
                Turn saved food videos into recipes you'll actually cook.
              </Text>
              <Text className="mt-6 max-w-[860px] text-center text-[18px] leading-9 text-[#6B7180]">
                Cooksy extracts ingredients, steps, timings, and confidence from TikTok, Instagram, and YouTube so you can stop rewatching videos and start cooking with clarity.
              </Text>

              <View className="mt-10 flex-row flex-wrap justify-center" style={{ gap: 14 }}>
                <Link href={"/home" as never} asChild>
                  <Pressable
                    className="rounded-full border border-[#23262E] bg-[#16181D] px-7 py-4"
                    style={{ shadowColor: "#16181D", shadowOpacity: 0.14, shadowRadius: 10, shadowOffset: { width: 0, height: 4 } }}
                  >
                    <View className="flex-row items-center" style={{ gap: 10 }}>
                      <Text className="text-[16px] font-semibold text-white">Try Cooksy free</Text>
                      <View className="h-7 w-7 items-center justify-center rounded-full bg-white">
                        <ArrowRight size={15} color="#111111" />
                      </View>
                    </View>
                  </Pressable>
                </Link>

                <Link href="/recipes" asChild>
                  <Pressable className="px-4 py-4">
                    <Text className="text-[16px] font-semibold text-ink">See how it works</Text>
                  </Pressable>
                </Link>
              </View>

              <View className="mt-10 flex-row flex-wrap justify-center" style={{ gap: 12 }}>
                {highlights.map((item) => (
                  <View key={item} className="flex-row items-center rounded-full border border-[#E8EAF0] bg-white px-4 py-3" style={softShadow}>
                    <CheckCircle2 size={16} color="#4A8BFF" />
                    <Text className="ml-2 text-[13px] font-medium text-[#5E6473]">{item}</Text>
                  </View>
                ))}
              </View>
            </View>

            <HeroDashboard />
          </View>

          <View className="mt-14 flex-row flex-wrap" style={{ gap: 16 }}>
            {features.map((feature, index) => {
              const Icon = feature.icon;
              const emphasized = index === 1;
              return (
                <View
                  key={feature.title}
                  className={`${isDesktop ? "flex-1" : "w-full"} rounded-[28px] border px-5 py-6`}
                  style={{
                    minWidth: isDesktop ? 0 : undefined,
                    borderColor: emphasized ? "#D7E6FF" : "#E7EAF1",
                    backgroundColor: emphasized ? "#F3F8FF" : "#FFFFFF"
                  }}
                >
                  <View className="mb-5 h-11 w-11 items-center justify-center rounded-full bg-[#F6F8FC]">
                    <Icon size={18} color="#111111" />
                  </View>
                  <Text className="text-[26px] font-bold leading-[30px] text-ink">{feature.title}</Text>
                  <Text className="mt-3 text-[14px] leading-7 text-[#68707F]">{feature.body}</Text>
                </View>
              );
            })}
          </View>

          <View className="mt-16 flex-row flex-wrap" style={{ gap: 16 }}>
            <View className={`${isDesktop ? "flex-[1.15]" : "w-full"} overflow-hidden rounded-[30px] border border-[#E7EAF1] bg-white`}>
              <View className="p-6">
                <SectionPill>Food-first visual system</SectionPill>
                <Text className="mt-5 max-w-[520px] text-[42px] font-bold leading-[46px] text-ink">
                  The recipe still feels like the food that made you save it.
                </Text>
                <Text className="mt-4 max-w-[560px] text-[15px] leading-8 text-[#68707F]">
                  Cooksy keeps the visual spark of the original post, then adds the structure that helps you decide, shop, and cook with less friction.
                </Text>
              </View>
              <View className="px-6 pb-6">
                <View className={`${isTablet ? "flex-row" : "flex-col"}`} style={{ gap: 14 }}>
                  <View className={`${isTablet ? "flex-[0.9]" : "w-full"}`}>
                    <FoodPhoto source={bowlImage} height={isTablet ? 420 : 340} rounded={28} label="Imported recipe" tone="dark" />
                  </View>
                  <View className={`${isTablet ? "flex-[0.72]" : "w-full"}`} style={{ gap: 14 }}>
                    <View className="rounded-[24px] border border-[#ECEFF4] bg-[#FCFCFD] px-5 py-5">
                      <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-[#7C8593]">What you pay for</Text>
                      <Text className="mt-4 text-[28px] font-bold leading-[32px] text-ink">Less rewriting. Less guessing. Less back-and-forth.</Text>
                      <Text className="mt-3 text-[14px] leading-7 text-[#667080]">
                        The result is ready to review and act on without manually pulling steps and ingredient guesses out of a video.
                      </Text>
                    </View>
                    <View className="flex-row" style={{ gap: 14 }}>
                      <View className="flex-1">
                        <FoodPhoto source={paneerImage} height={isTablet ? 188 : 180} rounded={24} label="Weeknight" />
                      </View>
                      <View className="flex-1">
                        <FoodPhoto source={friesImage} height={isTablet ? 188 : 180} rounded={24} label="Comfort" />
                      </View>
                    </View>
                  </View>
                </View>
              </View>
            </View>

            <LinearGradient
              colors={["#FFF8D9", "#F5C400", "#FFE780"]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              className={`${isDesktop ? "flex-[0.85]" : "w-full"} rounded-[30px] border border-[#F4DB66] px-6 py-6`}
            >
              <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-[#7A5B00]">Why people buy Cooksy</Text>
              <Text className="mt-5 text-[42px] font-bold leading-[46px] text-ink">
                It saves the time between "that looks good" and "let's make it".
              </Text>
              <Text className="mt-4 text-[15px] leading-8 text-[#5E520E]">
                Cooksy earns its place by removing the annoying part of internet recipes: rewriting vague content into something you can trust enough to cook tonight.
              </Text>
              <View className="mt-8 rounded-[26px] border border-[#F6E28B] bg-white/70 p-3">
                <FoodPhoto source={paneerImage} height={320} rounded={22} label="Cooksy mood" tone="dark" />
                <View className="mt-4 rounded-[22px] bg-white/80 px-4 py-4">
                  <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-[#7A5B00]">Value in practice</Text>
                  <Text className="mt-3 text-[24px] font-bold leading-[30px] text-ink">
                    Faster imports, clearer recipes, easier fixes, and a grocery list before you leave the page.
                  </Text>
                  <Link href={"/home" as never} asChild>
                    <Pressable className="mt-4 self-start rounded-full border border-[#23262E] bg-[#16181D] px-5 py-3">
                      <View className="flex-row items-center" style={{ gap: 8 }}>
                        <Text className="text-[14px] font-semibold text-white">Get Cooksy</Text>
                        <ArrowRight size={14} color="#FFFFFF" />
                      </View>
                    </Pressable>
                  </Link>
                </View>
              </View>
            </LinearGradient>
          </View>

          <View className="mt-16 items-center px-3">
            <SectionPill>How it works</SectionPill>
            <Text className="mt-6 max-w-[820px] text-center text-[50px] font-bold leading-[54px] text-ink">
              Cooksy is built to get you from inspiration to action fast.
            </Text>
          </View>

          <View className="mt-10 flex-row flex-wrap" style={{ gap: 16 }}>
            {[
              {
                title: "Import",
                body: "Save the post once and let Cooksy extract the title, ingredients, steps, and timing in the background."
              },
              {
                title: "Review",
                body: "Check what Cooksy inferred, fix anything uncertain, and make sure the recipe looks right before you shop."
              },
              {
                title: "Cook",
                body: "Open grocery mode or cooking mode immediately, instead of leaving the recipe trapped in a saved-video graveyard."
              }
            ].map((step, index) => (
              <View
                key={step.title}
                className={`${isDesktop ? "flex-1" : "w-full"} rounded-[28px] border border-[#E7EAF1] bg-white px-5 py-6`}
              >
                <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-[#7D8594]">{String(index + 1).padStart(2, "0")}</Text>
                <Text className="mt-5 text-[32px] font-bold leading-[36px] text-ink">{step.title}</Text>
                <Text className="mt-3 text-[15px] leading-7 text-[#68707F]">{step.body}</Text>
              </View>
            ))}
          </View>

          <View className="mt-16 flex-row flex-wrap" style={{ gap: 16 }}>
            <View className={`${isDesktop ? "flex-[1.2]" : "w-full"} rounded-[30px] border border-[#E7EAF1] bg-white px-6 py-6`}>
              <SectionPill>Why it converts</SectionPill>
              <Text className="mt-5 max-w-[560px] text-[46px] font-bold leading-[50px] text-ink">
                People pay for Cooksy because it removes friction from a habit they already have.
              </Text>
              <Text className="mt-4 max-w-[520px] text-[15px] leading-8 text-[#68707F]">
                They already save food posts. Cooksy turns those saves into something usable enough to cook from, which makes the value obvious in the first session.
              </Text>
            </View>

            <View className={`${isDesktop ? "flex-[0.8]" : "w-full"} rounded-[30px] border border-[#E7EAF1] bg-[#F4F8FF] px-6 py-6`}>
              <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-[#6F7C93]">What users get</Text>
              <View className="mt-5" style={{ gap: 16 }}>
                {[
                  { icon: Sparkles, text: "Confidence and evidence before they trust a recipe" },
                  { icon: ShoppingBag, text: "A grocery list without rewatching the video" },
                  { icon: Clock3, text: "Guided cooking mode when they are ready to make it" }
                ].map((item) => {
                  const Icon = item.icon;
                  return (
                    <View key={item.text} className="flex-row items-start" style={{ gap: 10 }}>
                      <Icon size={16} color="#111111" style={{ marginTop: 5 }} />
                      <Text className="flex-1 text-[15px] leading-7 text-[#556071]">{item.text}</Text>
                    </View>
                  );
                })}
              </View>
            </View>
          </View>

          <View className="mt-16 items-center px-3">
            <SectionPill>FAQ</SectionPill>
            <Text className="mt-6 max-w-[760px] text-center text-[44px] font-bold leading-[48px] text-ink">
              Questions people ask before they try Cooksy
            </Text>
          </View>

          <View className="mt-8" style={{ gap: 12 }}>
            {faqs.map((faq, index) => (
              <View key={faq.question} className="rounded-[26px] border border-[#E7EAF1] bg-white px-5 py-5">
                <View className="flex-row items-start" style={{ gap: 12 }}>
                  <Text className="w-8 text-[13px] font-bold text-[#8A91A0]">{String(index + 1).padStart(2, "0")}</Text>
                  <View className="flex-1">
                    <Text className="text-[22px] font-bold leading-[28px] text-ink">{faq.question}</Text>
                    <Text className="mt-3 text-[15px] leading-7 text-[#68707F]">{faq.answer}</Text>
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
