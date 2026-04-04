import { createClient } from "@supabase/supabase-js";

import { appEnv, hasSupabaseConfig } from "@/lib/env";

export const supabase = hasSupabaseConfig
  ? createClient(appEnv.supabaseUrl!, appEnv.supabaseAnonKey!, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: false
      }
    })
  : null;
