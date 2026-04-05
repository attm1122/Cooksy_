import { supabase } from "@/lib/supabase";

type SessionSnapshot = {
  userId?: string;
  email?: string;
  fullName?: string;
  errorMessage?: string;
};

type AuthErrorMode = "request" | "verify";

const getErrorMessage = (error: unknown) => {
  if (error instanceof Error) {
    return error.message;
  }

  if (typeof error === "string") {
    return error;
  }

  return undefined;
};

export const getCooksyAuthErrorMessage = (error: unknown, mode: AuthErrorMode) => {
  const rawMessage = getErrorMessage(error)?.trim().toLowerCase() ?? "";

  if (!rawMessage) {
    return mode === "request"
      ? "Cooksy could not send your sign-in code. Please try again."
      : "Cooksy could not verify that code. Please try again.";
  }

  if (rawMessage.includes("email rate limit exceeded") || rawMessage.includes("over_email_send_rate_limit")) {
    return "Too many codes were requested recently. Please wait a minute, then try again.";
  }

  if (rawMessage.includes("invalid") && rawMessage.includes("email")) {
    return "Enter a valid email address to create your Cooksy profile.";
  }

  if (rawMessage.includes("expired") && rawMessage.includes("token")) {
    return "That code has expired. Request a new code and try again.";
  }

  if (rawMessage.includes("otp_expired")) {
    return "That sign-in link has expired. Request a new code and try again.";
  }

  if (rawMessage.includes("access_denied")) {
    return "That sign-in link is no longer valid. Request a new code and try again.";
  }

  if (rawMessage.includes("token") && rawMessage.includes("invalid")) {
    return "That code doesn’t look right. Check the latest email from Cooksy and try again.";
  }

  if (rawMessage.includes("auth is not configured yet")) {
    return "Cooksy sign-in is temporarily unavailable on this deployment.";
  }

  return mode === "request"
    ? "Cooksy could not send your sign-in code right now. Please try again in a moment."
    : "Cooksy could not verify that code. Please check it and try again.";
};

const getCooksyEmailRedirectUrl = () => {
  if (typeof window !== "undefined" && window.location.origin) {
    return `${window.location.origin}/auth`;
  }

  return undefined;
};

export const ensureCooksySession = async () => {
  if (!supabase) {
    return { userId: undefined, email: undefined, fullName: undefined, errorMessage: undefined };
  }

  const { data: sessionData, error: sessionError } = await supabase.auth.getSession();

  if (sessionError) {
    return { userId: undefined, email: undefined, fullName: undefined, errorMessage: sessionError.message };
  }

  const user = sessionData.session?.user;

  if (user?.id) {
    return {
      userId: user.id,
      email: user.email,
      fullName: typeof user.user_metadata?.full_name === "string" ? user.user_metadata.full_name : undefined,
      errorMessage: undefined
    };
  }

  return { userId: undefined, email: undefined, fullName: undefined, errorMessage: undefined };
};

export const requestCooksyProfileAccess = async (email: string, fullName: string) => {
  if (!supabase) {
    throw new Error("Cooksy auth is not configured yet.");
  }

  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      shouldCreateUser: true,
      emailRedirectTo: getCooksyEmailRedirectUrl(),
      data: {
        full_name: fullName
      }
    }
  });

  if (error) {
    throw error;
  }
};

export const verifyCooksyProfileCode = async (email: string, token: string, fullName: string) => {
  if (!supabase) {
    throw new Error("Cooksy auth is not configured yet.");
  }

  const { data, error } = await supabase.auth.verifyOtp({
    email,
    token,
    type: "email"
  });

  if (error) {
    throw error;
  }

  if (fullName && data.user) {
    const metadataName = typeof data.user.user_metadata?.full_name === "string" ? data.user.user_metadata.full_name : undefined;

    if (metadataName !== fullName) {
      const { error: updateError } = await supabase.auth.updateUser({
        data: {
          full_name: fullName
        }
      });

      if (updateError) {
        throw updateError;
      }
    }
  }

  return {
    userId: data.user?.id,
    email: data.user?.email,
    fullName
  };
};

export const completeCooksyEmailLink = async (urlString: string, fallbackFullName?: string) => {
  if (!supabase) {
    throw new Error("Cooksy auth is not configured yet.");
  }

  const url = new URL(urlString);
  const queryParams = new URLSearchParams(url.search);
  const hashParams = new URLSearchParams(url.hash.replace(/^#/, ""));

  const errorCode = hashParams.get("error_code") ?? queryParams.get("error_code");
  const errorDescription = hashParams.get("error_description") ?? queryParams.get("error_description");

  if (errorCode || errorDescription) {
    throw new Error(errorDescription ?? errorCode ?? "Cooksy could not complete that sign-in link");
  }

  const authCode = queryParams.get("code");

  if (authCode) {
    const { data, error } = await supabase.auth.exchangeCodeForSession(authCode);

    if (error) {
      throw error;
    }

    return {
      userId: data.user?.id,
      email: data.user?.email,
      fullName: typeof data.user?.user_metadata?.full_name === "string" ? data.user.user_metadata.full_name : fallbackFullName
    };
  }

  const tokenHash = hashParams.get("token_hash");
  const type = hashParams.get("type");

  if (tokenHash && type) {
    const { data, error } = await supabase.auth.verifyOtp({
      token_hash: tokenHash,
      type: type as "signup" | "invite" | "magiclink" | "recovery" | "email_change" | "email"
    });

    if (error) {
      throw error;
    }

    return {
      userId: data.user?.id,
      email: data.user?.email,
      fullName: typeof data.user?.user_metadata?.full_name === "string" ? data.user.user_metadata.full_name : fallbackFullName
    };
  }

  return undefined;
};

export const signOutCooksy = async () => {
  if (!supabase) {
    return;
  }

  const { error } = await supabase.auth.signOut();

  if (error) {
    throw error;
  }
};

export const subscribeToCooksyAuth = (onChange: (snapshot: SessionSnapshot) => void) => {
  if (!supabase) {
    return () => undefined;
  }

  const {
    data: { subscription }
  } = supabase.auth.onAuthStateChange((_event, session) => {
    const user = session?.user;

    onChange({
      userId: user?.id,
      email: user?.email,
      fullName: typeof user?.user_metadata?.full_name === "string" ? user.user_metadata.full_name : undefined
    });
  });

  return () => subscription.unsubscribe();
};
