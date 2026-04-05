import { zodResolver } from "@hookform/resolvers/zod";
import { router } from "expo-router";
import { Apple, Globe, Mail, ShieldCheck, UserRound } from "lucide-react-native";
import { useEffect, useMemo, useState } from "react";
import { Controller, useForm } from "react-hook-form";
import { Platform, Text, TextInput, View } from "react-native";

import { PrimaryButton, SecondaryButton } from "@/components/common/Buttons";
import { CooksyCard } from "@/components/common/CooksyCard";
import { CooksyLogo } from "@/components/common/CooksyLogo";
import { ScreenContainer } from "@/components/common/ScreenContainer";
import { createProfileSchema, type CreateProfileValues, verifyProfileCodeSchema, type VerifyProfileCodeValues } from "@/lib/auth-schemas";
import { completeCooksyEmailLink, getCooksyAuthErrorMessage, requestCooksyProfileAccess, signInWithCooksyOAuth, type CooksyOAuthProvider, verifyCooksyProfileCode } from "@/lib/auth";
import { trackEvent } from "@/lib/analytics";
import { captureError } from "@/lib/monitoring";
import { useAuthStore } from "@/store/use-auth-store";

export default function AuthScreen() {
  const setAuthState = useAuthStore((state) => state.setAuthState);
  const [requestedEmail, setRequestedEmail] = useState<string>();
  const [requestedName, setRequestedName] = useState<string>();
  const [requestError, setRequestError] = useState<string>();
  const [verifyError, setVerifyError] = useState<string>();
  const [isRequesting, setIsRequesting] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);
  const [oauthLoadingProvider, setOauthLoadingProvider] = useState<CooksyOAuthProvider>();
  const [requestCooldownUntil, setRequestCooldownUntil] = useState<number>();
  const [cooldownNow, setCooldownNow] = useState(() => Date.now());

  useEffect(() => {
    if (!requestCooldownUntil || requestCooldownUntil <= Date.now()) {
      return undefined;
    }

    const interval = setInterval(() => {
      setCooldownNow(Date.now());
    }, 1000);

    return () => clearInterval(interval);
  }, [requestCooldownUntil]);

  const cooldownSeconds = useMemo(() => {
    if (!requestCooldownUntil) {
      return 0;
    }

    return Math.max(0, Math.ceil((requestCooldownUntil - cooldownNow) / 1000));
  }, [cooldownNow, requestCooldownUntil]);

  const isRequestCoolingDown = cooldownSeconds > 0;
  const requestButtonLabel = isRequestCoolingDown ? `Try again in ${cooldownSeconds}s` : "Create profile";
  const oauthProviders = useMemo(() => {
    const providers: { provider: CooksyOAuthProvider; label: string; icon: typeof Apple }[] = [];

    if (Platform.OS !== "android") {
      providers.push({ provider: "apple", label: "Continue with Apple", icon: Apple });
    }

    providers.push({ provider: "google", label: "Continue with Google", icon: Globe });

    return providers;
  }, []);

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }

    const hasAuthCallback =
      window.location.search.includes("code=") ||
      window.location.hash.includes("token_hash=") ||
      window.location.hash.includes("error_code=") ||
      window.location.search.includes("error_code=");

    if (!hasAuthCallback) {
      return;
    }

    let cancelled = false;

    const run = async () => {
      setVerifyError(undefined);
      setRequestError(undefined);
      setIsVerifying(true);

      try {
        const session = await completeCooksyEmailLink(window.location.href);

        if (!session || cancelled) {
          return;
        }

        setAuthState({
          status: "ready",
          userId: session.userId,
          email: session.email,
          fullName: session.fullName,
          errorMessage: undefined
        });

        const cleanUrl = `${window.location.origin}/auth`;
        window.history.replaceState({}, "", cleanUrl);
        router.replace("/home" as never);
      } catch (error) {
        if (!cancelled) {
          setVerifyError(getCooksyAuthErrorMessage(error, "verify"));
          captureError(error, { action: "complete_email_link" });
        }
      } finally {
        if (!cancelled) {
          setIsVerifying(false);
        }
      }
    };

    void run();

    return () => {
      cancelled = true;
    };
  }, [setAuthState]);

  const createProfileForm = useForm<CreateProfileValues>({
    resolver: zodResolver(createProfileSchema),
    defaultValues: {
      fullName: "",
      email: ""
    }
  });

  const verifyCodeForm = useForm<VerifyProfileCodeValues>({
    resolver: zodResolver(verifyProfileCodeSchema),
    defaultValues: {
      token: ""
    }
  });

  const onCreateProfile = createProfileForm.handleSubmit(async ({ email, fullName }) => {
    if (isRequestCoolingDown) {
      return;
    }

    setRequestError(undefined);
    setIsRequesting(true);

    try {
      await requestCooksyProfileAccess(email.trim().toLowerCase(), fullName.trim());
      setRequestCooldownUntil(undefined);
      setRequestedEmail(email.trim().toLowerCase());
      setRequestedName(fullName.trim());
      trackEvent("auth_code_requested", {
        emailDomain: email.split("@")[1] ?? "unknown"
      });
    } catch (error) {
      const message = getCooksyAuthErrorMessage(error, "request");
      setRequestError(message);
      if (message.toLowerCase().includes("wait a minute")) {
        setRequestCooldownUntil(Date.now() + 60_000);
        setCooldownNow(Date.now());
      }
      captureError(error, { action: "request_profile_access" });
    } finally {
      setIsRequesting(false);
    }
  });

  const onVerifyCode = verifyCodeForm.handleSubmit(async ({ token }) => {
    if (!requestedEmail || !requestedName) {
      return;
    }

    setVerifyError(undefined);
    setIsVerifying(true);

    try {
      const session = await verifyCooksyProfileCode(requestedEmail, token, requestedName);
      setAuthState({
        status: "ready",
        userId: session.userId,
        email: session.email,
        fullName: session.fullName,
        errorMessage: undefined
      });
      trackEvent("onboarding_completed", {
        hasName: Boolean(session.fullName)
      });
      router.replace("/home" as never);
    } catch (error) {
      const message = getCooksyAuthErrorMessage(error, "verify");
      setVerifyError(message);
      captureError(error, { action: "verify_profile_code" });
    } finally {
      setIsVerifying(false);
    }
  });

  const onOAuthSignIn = async (provider: CooksyOAuthProvider) => {
    setRequestError(undefined);
    setVerifyError(undefined);
    setOauthLoadingProvider(provider);

    try {
      const session = await signInWithCooksyOAuth(provider);

      if (session?.userId) {
        setAuthState({
          status: "ready",
          userId: session.userId,
          email: session.email,
          fullName: session.fullName,
          errorMessage: undefined
        });

        trackEvent("onboarding_completed", {
          provider,
          hasName: Boolean(session.fullName)
        });

        router.replace("/home" as never);
        return;
      }

      trackEvent("auth_social_started", { provider });
    } catch (error) {
      const message = getCooksyAuthErrorMessage(error, "request");
      setRequestError(message);
      captureError(error, { action: "social_sign_in", provider });
    } finally {
      setOauthLoadingProvider(undefined);
    }
  };

  return (
    <ScreenContainer showHeader={false} showBottomNav={false} keyboardAvoiding>
      <View className="mx-auto w-full max-w-[1120px] px-5 pb-14 pt-10">
        <View className="mb-8 items-center">
          <CooksyLogo size="lg" />
          <Text className="mt-6 text-center text-[42px] font-bold leading-[46px] text-ink">
            Create your profile and start Cooksy free
          </Text>
          <Text className="mt-4 max-w-[680px] text-center text-[16px] leading-8 text-muted">
            Save recipes to your personal library, sync across web and mobile, and keep your imports, books, and cooking history attached to your account.
          </Text>
        </View>

        <View className="flex-row flex-wrap" style={{ gap: 16 }}>
          <View className="flex-1" style={{ minWidth: 320 }}>
            <CooksyCard className="p-6">
              <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-[#7D8594]">Why create a profile</Text>
              <View className="mt-5" style={{ gap: 16 }}>
                {[
                  {
                    icon: UserRound,
                    title: "Save your recipes",
                    body: "Your imports, edits, and recipe books stay attached to you instead of disappearing into an anonymous session."
                  },
                  {
                    icon: ShieldCheck,
                    title: "Pick up anywhere",
                    body: "Start on web, then keep cooking on iPhone or Android with the same account."
                  },
                  {
                    icon: Mail,
                    title: "Try the free version first",
                    body: "Creating a profile gets you into Cooksy's free tier immediately, then you can upgrade later if you want more."
                  }
                ].map((item) => {
                  const Icon = item.icon;

                  return (
                    <View key={item.title} className="flex-row items-start" style={{ gap: 12 }}>
                      <View className="mt-1 h-10 w-10 items-center justify-center rounded-full bg-brand-yellow-soft">
                        <Icon size={18} color="#111111" />
                      </View>
                      <View className="flex-1">
                        <Text className="text-[18px] font-bold text-ink">{item.title}</Text>
                        <Text className="mt-2 text-[14px] leading-7 text-muted">{item.body}</Text>
                      </View>
                    </View>
                  );
                })}
              </View>
            </CooksyCard>
          </View>
          <View className="flex-1" style={{ minWidth: 320 }}>
            <CooksyCard className="p-6">
              {!requestedEmail ? (
                <>
                  <Text className="text-[28px] font-bold text-ink">Create your Cooksy profile</Text>
                  <Text className="mt-3 text-[15px] leading-7 text-muted">
                    Start with Apple or Google for the fastest setup, or use your email if you prefer a 6-digit code.
                  </Text>

                  <View className="mt-6" style={{ gap: 14 }}>
                    {oauthProviders.map(({ provider, label, icon: Icon }) => (
                      <SecondaryButton
                        key={provider}
                        fullWidth
                        disabled={Boolean(oauthLoadingProvider)}
                        onPress={() => {
                          void onOAuthSignIn(provider);
                        }}
                      >
                        <View className="flex-row items-center justify-center" style={{ gap: 10 }}>
                          <Icon size={18} color="#111111" />
                          <Text className="text-[15px] font-semibold text-soft-ink">
                            {oauthLoadingProvider === provider ? "Opening..." : label}
                          </Text>
                        </View>
                      </SecondaryButton>
                    ))}

                    <View className="flex-row items-center" style={{ gap: 12 }}>
                      <View className="h-px flex-1 bg-line" />
                      <Text className="text-[12px] font-semibold uppercase tracking-[1px] text-[#8A8478]">Or use email</Text>
                      <View className="h-px flex-1 bg-line" />
                    </View>

                    <Controller
                      control={createProfileForm.control}
                      name="fullName"
                      render={({ field: { onChange, value } }) => (
                        <TextInput
                          value={value}
                          onChangeText={onChange}
                          placeholder="Full name"
                          placeholderTextColor="#8A8478"
                          className="rounded-[20px] border border-line bg-cream px-4 py-4 text-[15px] text-soft-ink"
                        />
                      )}
                    />
                    {createProfileForm.formState.errors.fullName ? (
                      <Text className="text-[13px] text-danger">{createProfileForm.formState.errors.fullName.message}</Text>
                    ) : null}

                    <Controller
                      control={createProfileForm.control}
                      name="email"
                      render={({ field: { onChange, value } }) => (
                        <TextInput
                          value={value}
                          onChangeText={onChange}
                          keyboardType="email-address"
                          autoCapitalize="none"
                          autoCorrect={false}
                          placeholder="Email address"
                          placeholderTextColor="#8A8478"
                          className="rounded-[20px] border border-line bg-cream px-4 py-4 text-[15px] text-soft-ink"
                        />
                      )}
                    />
                    {createProfileForm.formState.errors.email ? (
                      <Text className="text-[13px] text-danger">{createProfileForm.formState.errors.email.message}</Text>
                    ) : null}

                    {requestError ? <Text className="text-[13px] text-danger">{requestError}</Text> : null}
                    {isRequestCoolingDown ? (
                      <Text className="text-[13px] text-muted">
                        We’re protecting delivery for everyone. Please wait {cooldownSeconds}s before requesting another code.
                      </Text>
                    ) : null}

                    <Text className="text-[13px] leading-6 text-muted">
                      Apple and Google are best if you plan to subscribe, because they keep your Cooksy account cleaner across web, iPhone, and Android.
                    </Text>

                    <PrimaryButton onPress={onCreateProfile} loading={isRequesting} disabled={isRequestCoolingDown}>
                      {requestButtonLabel}
                    </PrimaryButton>
                  </View>
                </>
              ) : (
                <>
                  <Text className="text-[28px] font-bold text-ink">Enter your code</Text>
                  <Text className="mt-3 text-[15px] leading-7 text-muted">
                    We sent a 6-digit code to {requestedEmail}. Enter it to finish your profile and unlock the free version of Cooksy.
                  </Text>

                  <View className="mt-6" style={{ gap: 14 }}>
                    <Controller
                      control={verifyCodeForm.control}
                      name="token"
                      render={({ field: { onChange, value } }) => (
                        <TextInput
                          value={value}
                          onChangeText={onChange}
                          keyboardType="number-pad"
                          autoCapitalize="none"
                          autoCorrect={false}
                          placeholder="6-digit code"
                          placeholderTextColor="#8A8478"
                          className="rounded-[20px] border border-line bg-cream px-4 py-4 text-[18px] text-soft-ink"
                        />
                      )}
                    />
                    {verifyCodeForm.formState.errors.token ? (
                      <Text className="text-[13px] text-danger">{verifyCodeForm.formState.errors.token.message}</Text>
                    ) : null}

                    {verifyError ? <Text className="text-[13px] text-danger">{verifyError}</Text> : null}

                    <PrimaryButton onPress={onVerifyCode} loading={isVerifying}>
                      Finish profile
                    </PrimaryButton>
                    <SecondaryButton
                      onPress={() => {
                        setRequestedEmail(undefined);
                        setRequestedName(undefined);
                        verifyCodeForm.reset();
                      }}
                    >
                      Use a different email
                    </SecondaryButton>
                  </View>
                </>
              )}
            </CooksyCard>
          </View>
        </View>
      </View>
    </ScreenContainer>
  );
}
