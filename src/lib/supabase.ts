import { createClient } from "@supabase/supabase-js";

import { appEnv, hasSupabaseConfig } from "@/lib/env";

export const supabase = hasSupabaseConfig
  ? createClient(appEnv.supabaseUrl!, appEnv.supabaseAnonKey!, {
      auth: {
        persistSession: false,
        autoRefreshToken: false
      }
    })
  : null;
