import { z } from "zod";

import type { ImportBackendMode } from "@/types/ingestion";

const publicEnvSchema = z.object({
  EXPO_PUBLIC_RECIPE_IMPORT_MODE: z.enum(["mock", "remote", "auto"]).optional(),
  EXPO_PUBLIC_SUPABASE_URL: z.string().url().optional().or(z.literal("")),
  EXPO_PUBLIC_SUPABASE_ANON_KEY: z.string().optional().or(z.literal(""))
});

const publicEnv = publicEnvSchema.parse({
  EXPO_PUBLIC_RECIPE_IMPORT_MODE: process.env.EXPO_PUBLIC_RECIPE_IMPORT_MODE,
  EXPO_PUBLIC_SUPABASE_URL: process.env.EXPO_PUBLIC_SUPABASE_URL,
  EXPO_PUBLIC_SUPABASE_ANON_KEY: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY
});

export const appEnv = {
  recipeImportMode: (publicEnv.EXPO_PUBLIC_RECIPE_IMPORT_MODE ?? "mock") as ImportBackendMode,
  supabaseUrl: publicEnv.EXPO_PUBLIC_SUPABASE_URL || undefined,
  supabaseAnonKey: publicEnv.EXPO_PUBLIC_SUPABASE_ANON_KEY || undefined
};

export const hasSupabaseConfig = Boolean(appEnv.supabaseUrl && appEnv.supabaseAnonKey);
