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
