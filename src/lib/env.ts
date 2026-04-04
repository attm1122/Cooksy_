import { z } from "zod";

import type { ImportBackendMode } from "@/types/ingestion";

const publicEnvSchema = z.object({
  EXPO_PUBLIC_RECIPE_IMPORT_MODE: z.enum(["mock", "remote", "auto"]).optional(),
  EXPO_PUBLIC_SUPABASE_URL: z.string().url().optional().or(z.literal("")),
  EXPO_PUBLIC_SUPABASE_ANON_KEY: z.string().optional().or(z.literal("")),
  // Extraction API keys (optional - for enhanced extraction)
  EXPO_PUBLIC_RAPIDAPI_KEY: z.string().optional().or(z.literal("")),
  EXPO_PUBLIC_RAPIDAPI_HOST: z.string().optional().or(z.literal("")),
  EXPO_PUBLIC_OPENAI_API_KEY: z.string().optional().or(z.literal("")),
  // Extraction configuration
  EXPO_PUBLIC_EXTRACTION_TIMEOUT_MS: z.string().optional().or(z.literal("")),
  EXPO_PUBLIC_ENABLE_TIKTOK_SCRAPING: z.enum(["true", "false"]).optional().or(z.literal("")),
  EXPO_PUBLIC_ENABLE_INSTAGRAM_SCRAPING: z.enum(["true", "false"]).optional().or(z.literal("")),
  EXPO_PUBLIC_ENABLE_WHISPER_TRANSCRIPTION: z.enum(["true", "false"]).optional().or(z.literal(""))
});

const publicEnv = publicEnvSchema.parse({
  EXPO_PUBLIC_RECIPE_IMPORT_MODE: process.env.EXPO_PUBLIC_RECIPE_IMPORT_MODE,
  EXPO_PUBLIC_SUPABASE_URL: process.env.EXPO_PUBLIC_SUPABASE_URL,
  EXPO_PUBLIC_SUPABASE_ANON_KEY: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY,
  EXPO_PUBLIC_RAPIDAPI_KEY: process.env.EXPO_PUBLIC_RAPIDAPI_KEY,
  EXPO_PUBLIC_RAPIDAPI_HOST: process.env.EXPO_PUBLIC_RAPIDAPI_HOST,
  EXPO_PUBLIC_OPENAI_API_KEY: process.env.EXPO_PUBLIC_OPENAI_API_KEY,
  EXPO_PUBLIC_EXTRACTION_TIMEOUT_MS: process.env.EXPO_PUBLIC_EXTRACTION_TIMEOUT_MS,
  EXPO_PUBLIC_ENABLE_TIKTOK_SCRAPING: process.env.EXPO_PUBLIC_ENABLE_TIKTOK_SCRAPING,
  EXPO_PUBLIC_ENABLE_INSTAGRAM_SCRAPING: process.env.EXPO_PUBLIC_ENABLE_INSTAGRAM_SCRAPING,
  EXPO_PUBLIC_ENABLE_WHISPER_TRANSCRIPTION: process.env.EXPO_PUBLIC_ENABLE_WHISPER_TRANSCRIPTION
});

export const appEnv = {
  recipeImportMode: (publicEnv.EXPO_PUBLIC_RECIPE_IMPORT_MODE ?? "mock") as ImportBackendMode,
  supabaseUrl: publicEnv.EXPO_PUBLIC_SUPABASE_URL || undefined,
  supabaseAnonKey: publicEnv.EXPO_PUBLIC_SUPABASE_ANON_KEY || undefined,
  // Extraction configuration
  rapidApiKey: publicEnv.EXPO_PUBLIC_RAPIDAPI_KEY || undefined,
  rapidApiHost: publicEnv.EXPO_PUBLIC_RAPIDAPI_HOST || undefined,
  openAiApiKey: publicEnv.EXPO_PUBLIC_OPENAI_API_KEY || undefined,
  extractionTimeoutMs: Number(publicEnv.EXPO_PUBLIC_EXTRACTION_TIMEOUT_MS || "30000"),
  enableTikTokScraping: publicEnv.EXPO_PUBLIC_ENABLE_TIKTOK_SCRAPING === "true",
  enableInstagramScraping: publicEnv.EXPO_PUBLIC_ENABLE_INSTAGRAM_SCRAPING === "true",
  enableWhisperTranscription: publicEnv.EXPO_PUBLIC_ENABLE_WHISPER_TRANSCRIPTION === "true"
};

export const hasSupabaseConfig = Boolean(appEnv.supabaseUrl && appEnv.supabaseAnonKey);
export const hasRapidApiConfig = Boolean(appEnv.rapidApiKey && appEnv.rapidApiHost);
export const hasOpenAiConfig = Boolean(appEnv.openAiApiKey);
