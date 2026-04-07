import { Link } from "expo-router";
import { ArrowRight, ChevronRight } from "lucide-react-native";
import { Image, Pressable, ScrollView, Text, View, useWindowDimensions } from "react-native";

import { CooksyLogo } from "@/components/common/CooksyLogo";

const bowlImage = require("../../../assets/landing/bowl.jpg");
const noodlesImage = require("../../../assets/landing/noodles.jpg");
const paneerImage = require("../../../assets/landing/spiced-paneer.jpg");

const navItems = [
  { label: "How it works", href: "/auth" },
  { label: "Features", href: "/auth" },
  { label: "Recipes", href: "/auth" }
] as const;

const benefits = [
  {
    title: "Less chaos",
    body: "No more digging through captions, comments, screenshots, and half-saved bookmarks."
  },
  {
    title: "More trust",
    body: "Confidence notes show what Cooksy inferred so you know what to review before you cook."
  },
  {
    title: "Better organisation",
    body: "Save recipes into books that match how you actually cook, not how platforms sort content."
  },
  {
    title: "Cross-platform",
    body: "Start on web, save on mobile, and cook later on iPhone, Android, or desktop."
  }
] as const;

const footerColumns = [
  {
    title: "Product",
    links: ["Features", "How it works", "Pricing"]
  },
  {
    title: "Company",
    links: ["About", "Blog", "Careers"]
  },
  {
    title: "Legal",
    links: ["Privacy", "Terms", "Cookie Policy"]
  }
] as const;

const softShadow = {
  shadowColor: "#111111",
  shadowOpacity: 0.08,
  shadowRadius: 24,
  shadowOffset: { width: 0, height: 12 }
} as const;

const PrimaryCta = ({ label, href }: { label: string; href: string }) => (
  <Link href={href as never} asChild>
    <Pressable
      className="rounded-full bg-brand-yellow px-7 py-4"
      style={{ shadowColor: "#E6B800", shadowOpacity: 0.18, shadowRadius: 14, shadowOffset: { width: 0, height: 6 } }}
    >
      <View className="flex-row items-center justify-center" style={{ gap: 8 }}>
        <Text className="text-[16px] font-semibold text-ink">{label}</Text>
        <ArrowRight size={16} color="#111111" />
      </View>
    </Pressable>
  </Link>
);

const SecondaryCta = ({ label, href }: { label: string; href: string }) => (
  <Link href={href as never} asChild>
    <Pressable className="rounded-full border border-[#E1E1E1] bg-white px-7 py-4">
      <View className="flex-row items-center justify-center" style={{ gap: 8 }}>
        <Text className="text-[16px] font-semibold text-ink">{label}</Text>
        <ChevronRight size={16} color="#111111" />
      </View>
    </Pressable>
  </Link>
);

const NavLink = ({ label, href }: { label: string; href: string }) => (
  <Link href={href as never} asChild>
    <Pressable className="px-2 py-2">
      <Text className="text-[15px] font-medium text-[#2D2D2D]">{label}</Text>
    </Pressable>
  </Link>
);

const BrowserMock = ({ compact = false }: { compact?: boolean }) => (
  <View className="overflow-hidden rounded-[30px] border border-[#E8E8E8] bg-white" style={softShadow}>
    <View className="flex-row items-center border-b border-[#ECECEC] px-6 py-4" style={{ gap: 8 }}>
      <View className="h-3 w-3 rounded-full bg-[#FF5F57]" />
      <View className="h-3 w-3 rounded-full bg-[#FFBD2E]" />
      <View className="h-3 w-3 rounded-full bg-[#28C840]" />
      <View className="ml-3 rounded-full bg-[#F3F4F7] px-4 py-2">
        <Text className="text-[13px] font-medium text-[#7D7D7D]">cooksy.app</Text>
      </View>
    </View>

    <View className={`${compact ? "p-5" : "p-6"}`}>
      <Text className="text-[15px] font-bold text-ink">Sticky visuals from the original</Text>
      <Text className="mt-2 text-[14px] leading-6 text-[#6A6A6A]">
        Use the source thumbnail as the base image so the saved recipe still feels familiar.
      </Text>

      <View className="mt-5 overflow-hidden rounded-[24px] bg-[#F7F5EF]">
        <Image source={bowlImage} resizeMode="cover" style={{ height: compact ? 210 : 260, width: "100%" }} />
      </View>

      <View className="mt-4 rounded-[22px] bg-white px-4 py-4" style={softShadow}>
        <Text className="text-[26px] font-bold text-ink">Creamy Garlic Pasta</Text>
        <Text className="mt-1 text-[14px] text-[#6D6D6D]">30 mins · 4 servings</Text>
      </View>

      <View className="mt-4 rounded-[18px] bg-[#FFF5BF] px-4 py-3">
        <Text className="text-[13px] font-medium text-[#6B5600]">Some quantities were estimated</Text>
      </View>

      <View className="mt-4" style={{ gap: 12 }}>
        {["Ingredients", "Steps", "Save to book"].map((label) => (
          <View key={label} className="rounded-[18px] bg-[#F5F6F8] px-4 py-4">
            <Text className="text-[14px] font-semibold text-[#333333]">{label}</Text>
          </View>
        ))}
      </View>
    </View>
  </View>
);

const PhoneMock = () => (
  <View
    className="self-center rounded-[48px] border-[10px] border-[#111111] bg-white px-5 pb-6 pt-5"
    style={{ width: 230, height: 460, shadowColor: "#111111", shadowOpacity: 0.12, shadowRadius: 24, shadowOffset: { width: 0, height: 16 } }}
  >
    <View className="self-center rounded-full bg-[#F0F1F4] px-6 py-1">
      <Text className="text-[11px] font-medium text-[#696969]">9:41</Text>
    </View>
    <View className="mt-4 overflow-hidden rounded-[26px] bg-[#F7F5EF]">
      <Image source={noodlesImage} resizeMode="cover" style={{ height: 180, width: "100%" }} />
    </View>
    <Text className="mt-5 text-[28px] font-bold text-ink">Spicy Miso Ramen</Text>
    <View className="mt-3 flex-row flex-wrap" style={{ gap: 8 }}>
      {["45 mins", "2 servings"].map((tag) => (
        <View key={tag} className="rounded-full bg-[#F7EDB0] px-3 py-2">
          <Text className="text-[12px] font-semibold text-[#6A5600]">{tag}</Text>
        </View>
      ))}
    </View>
    <View className="mt-4" style={{ gap: 10 }}>
      {["Ramen noodles", "Miso paste", "Chicken broth", "Soft boiled eggs"].map((item) => (
        <View key={item} className="flex-row items-center" style={{ gap: 10 }}>
          <View className="h-2.5 w-2.5 rounded-full bg-brand-yellow" />
          <Text className="text-[15px] text-[#333333]">{item}</Text>
        </View>
      ))}
    </View>
  </View>
);

const StepCard = ({ index, title, body }: { index: string; title: string; body: string }) => (
  <View className="flex-1 items-center px-4 py-6">
    <View className="h-16 w-16 items-center justify-center rounded-[18px] bg-brand-yellow">
      <Text className="text-[24px] font-bold text-ink">{index}</Text>
    </View>
    <Text className="mt-8 text-center text-[20px] font-bold text-ink">{title}</Text>
    <Text className="mt-3 max-w-[280px] text-center text-[15px] leading-7 text-[#666666]">{body}</Text>
  </View>
);

export const WebLandingPage = () => {
  const { width } = useWindowDimensions();
  const isDesktop = width >= 1180;
  const isTablet = width >= 800;

  return (
    <View className="flex-1 bg-[#FAF7EF]">
      <ScrollView showsVerticalScrollIndicator={false}>
        <View className="border-b border-[#ECE7DA] bg-[#FBF8F0] px-5 py-5">
          <View className="mx-auto w-full max-w-[1280px] flex-row items-center justify-between">
            <CooksyLogo size="md" />

            {isTablet ? (
              <View className="flex-row items-center" style={{ gap: 36 }}>
                {navItems.map((item) => (
                  <NavLink key={item.label} label={item.label} href={item.href} />
                ))}
              </View>
            ) : (
              <View />
            )}

            <PrimaryCta label="Get app" href="/auth" />
          </View>
        </View>

        <View className="bg-[#151515] px-5 py-20">
          <View className="mx-auto w-full max-w-[980px] items-center">
            <Text className="max-w-[820px] text-center text-[48px] font-bold leading-[56px] text-white" style={{ fontSize: isTablet ? 72 : 48, lineHeight: isTablet ? 80 : 56 }}>
              Save the food you discover. Actually cook it later.
            </Text>
            <Text className="mt-7 max-w-[760px] text-center text-[19px] leading-8 text-[#A9ACB4]">
              Cooksy turns social food content into clear, cookable recipes with strong visuals, trusted guidance, and a profile that keeps everything in one place.
            </Text>
            <View className="mt-10 flex-row flex-wrap justify-center" style={{ gap: 16 }}>
              <PrimaryCta label="Create profile free" href="/auth" />
              <SecondaryCta label="See product" href="/auth" />
            </View>
          </View>
        </View>

        <View className="bg-[#FBF8F0] px-5 py-16">
          <View className="mx-auto w-full max-w-[1280px]">
            <View className={`${isDesktop ? "flex-row" : "flex-col"}`} style={{ gap: 24 }}>
              <View className={`${isDesktop ? "flex-[1.15]" : "w-full"}`}>
                <BrowserMock compact={!isDesktop} />
              </View>
              <View className={`${isDesktop ? "flex-[0.85]" : "w-full"} items-center justify-center rounded-[34px] border border-[#ECE6D8] bg-[#FFFDF7] px-6 py-8`}>
                <PhoneMock />
              </View>
            </View>
          </View>
        </View>

        <View className="bg-white px-5 py-20">
          <View className="mx-auto w-full max-w-[1140px]">
            <Text className="text-center text-[44px] font-bold leading-[50px] text-ink" style={{ fontSize: isTablet ? 56 : 44, lineHeight: isTablet ? 62 : 50 }}>
              Why people would choose Cooksy
            </Text>
            <View className="mt-12 flex-row flex-wrap" style={{ gap: 20 }}>
              {benefits.map((item) => (
                <View
                  key={item.title}
                  className={`${isTablet ? "w-[48%]" : "w-full"} rounded-[28px] border border-[#ECE6D8] bg-[#FFFCF5] px-7 py-7`}
                  style={softShadow}
                >
                  <Text className="text-[24px] font-bold text-ink">{item.title}</Text>
                  <Text className="mt-4 text-[16px] leading-7 text-[#666666]">{item.body}</Text>
                </View>
              ))}
            </View>
          </View>
        </View>

        <View className="bg-[#FBF8F0] px-5 py-18">
          <View className="mx-auto w-full max-w-[1280px] overflow-hidden rounded-[34px] border border-[#ECE6D8] bg-white px-6 py-8">
            <View className="flex-row items-center border-b border-[#ECECEC] pb-5">
              <View className="rounded-full bg-[#F4F4F6] px-4 py-2">
                <Text className="text-[13px] font-medium text-[#7A7A7A]">cooksy.app</Text>
              </View>
            </View>

            <View className={`${isDesktop ? "flex-row" : "flex-col"} mt-8`} style={{ gap: 28 }}>
              <View className={`${isDesktop ? "flex-1" : "w-full"}`}>
                <Text className="text-[18px] font-bold text-ink">Sticky visuals from the original</Text>
                <Text className="mt-3 text-[15px] leading-7 text-[#666666]">
                  Use the source thumbnail as the base image so recipes feel familiar.
                </Text>
                <View className="mt-6 overflow-hidden rounded-[26px] bg-[#F7F5EF]">
                  <Image source={paneerImage} resizeMode="cover" style={{ height: 300, width: "100%" }} />
                </View>
                <View className="mt-4 rounded-[22px] bg-white px-5 py-5" style={softShadow}>
                  <Text className="text-[28px] font-bold text-ink">Creamy Garlic Pasta</Text>
                  <Text className="mt-2 text-[15px] text-[#666666]">30 mins · 4 servings</Text>
                </View>
                <View className="mt-4 rounded-[18px] bg-[#FFF4B6] px-4 py-3">
                  <Text className="text-[13px] font-medium text-[#715C00]">Some quantities were estimated</Text>
                </View>
              </View>

              <View className={`${isDesktop ? "w-[320px]" : "w-full"} items-center justify-center`}>
                <PhoneMock />
              </View>
            </View>
          </View>
        </View>

        <View className="bg-white px-5 py-20">
          <View className="mx-auto w-full max-w-[1200px]">
            <View className="flex-row flex-wrap justify-between" style={{ gap: 20 }}>
              <StepCard index="01" title="Paste any link" body="Import from TikTok, Instagram, or YouTube in seconds." />
              <StepCard index="02" title="Get a trusted recipe" body="Ingredients, steps, times, and confidence notes come through clearly." />
              <StepCard index="03" title="Save and cook later" body="Keep favourites in your profile and cook from any device when you're ready." />
            </View>

            <View className="mt-16 items-center">
              <Text className="text-center text-[48px] font-bold leading-[54px] text-ink" style={{ fontSize: isTablet ? 60 : 48, lineHeight: isTablet ? 66 : 54 }}>
                Available on web, iOS, and Android
              </Text>
              <Text className="mt-4 max-w-[760px] text-center text-[18px] leading-8 text-[#666666]">
                Create one Cooksy profile, save recipes anywhere, and keep your cooking flow synced across your devices.
              </Text>
            </View>
          </View>
        </View>

        <View className="border-t border-[#ECE7DA] bg-[#FBF8F0] px-5 py-14">
          <View className="mx-auto w-full max-w-[1280px]">
            <View className={`${isDesktop ? "flex-row" : "flex-col"}`} style={{ gap: 40 }}>
              <View className={`${isDesktop ? "w-[240px]" : "w-full"}`}>
                <CooksyLogo size="md" />
                <Text className="mt-5 text-[15px] leading-7 text-[#666666]">Turn food links into real recipes.</Text>
              </View>

              <View className="flex-1 flex-row flex-wrap justify-between" style={{ gap: 24 }}>
                {footerColumns.map((column) => (
                  <View key={column.title} className="min-w-[160px]">
                    <Text className="text-[18px] font-bold text-ink">{column.title}</Text>
                    <View className="mt-5" style={{ gap: 12 }}>
                      {column.links.map((item) => (
                        <Text key={item} className="text-[15px] text-[#666666]">
                          {item}
                        </Text>
                      ))}
                    </View>
                  </View>
                ))}
              </View>
            </View>

            <View className="mt-12 flex-row flex-wrap items-center justify-between border-t border-[#ECE7DA] pt-8" style={{ gap: 16 }}>
              <Text className="text-[14px] text-[#777777]">© 2026 Cooksy. All rights reserved.</Text>
              <View className="flex-row items-center" style={{ gap: 14 }}>
                {["YT", "IG"].map((label) => (
                  <View key={label} className="h-10 w-10 items-center justify-center rounded-full border border-[#E6E0D0] bg-white">
                    <Text className="text-[12px] font-bold text-ink">{label}</Text>
                  </View>
                ))}
              </View>
            </View>
          </View>
        </View>
      </ScrollView>
    </View>
  );
};
