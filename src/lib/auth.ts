import { supabase } from "@/lib/supabase";

export const ensureCooksySession = async () => {
  if (!supabase) {
    return { userId: undefined, errorMessage: undefined };
  }

  const { data: sessionData, error: sessionError } = await supabase.auth.getSession();

  if (sessionError) {
    return { userId: undefined, errorMessage: sessionError.message };
  }

  if (sessionData.session?.user?.id) {
    return { userId: sessionData.session.user.id, errorMessage: undefined };
  }

  const { data, error } = await supabase.auth.signInAnonymously();

  return {
    userId: data.user?.id,
    errorMessage: error?.message
  };
};

export const subscribeToCooksyAuth = (onChange: (userId?: string) => void) => {
  if (!supabase) {
    return () => undefined;
  }

  const {
    data: { subscription }
  } = supabase.auth.onAuthStateChange((_event, session) => {
    onChange(session?.user?.id);
  });

  return () => subscription.unsubscribe();
};
