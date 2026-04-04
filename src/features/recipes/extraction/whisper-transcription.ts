import { appEnv } from "@/lib/env";
import { captureError, captureMessage } from "@/lib/monitoring";
import type { TranscriptSegment } from "@/features/recipes/types";

export type WhisperTranscriptionResult = {
  success: true;
  transcript: string;
  segments: TranscriptSegment[];
  language: string;
  durationSeconds: number;
} | {
  success: false;
  error: string;
  retryable: boolean;
};

// Whisper API configuration
const WHISPER_API_URL = "https://api.openai.com/v1/audio/transcriptions";

// Audio extraction is complex on mobile, so we'll support multiple approaches:
// 1. Server-side extraction (for backend processing)
// 2. Third-party services (RapidAPI with audio support)
// 3. Client-side extraction (limited browser support)

type AudioSource = {
  type: "url" | "base64" | "blob";
  data: string | Blob;
  mimeType?: string;
};

/**
 * Transcribe audio using OpenAI Whisper API
 * This is intended for server-side use in Supabase Edge Functions
 */
export const transcribeWithWhisper = async (
  audioSource: AudioSource,
  options: {
    language?: string; // auto-detect if not specified
    prompt?: string;   // prompt to guide transcription
    responseFormat?: "json" | "verbose_json" | "srt" | "vtt";
  } = {}
): Promise<WhisperTranscriptionResult> => {
  // Check if we have API key
  const apiKey = process.env.OPENAI_API_KEY || appEnv.openAiApiKey;
  
  if (!apiKey) {
    return {
      success: false,
      error: "OpenAI API key not configured",
      retryable: false
    };
  }

  try {
    const formData = new FormData();
    
    // Add audio file
    if (audioSource.type === "url") {
      // Fetch audio from URL first
      const audioResponse = await fetch(audioSource.data as string, {
        signal: AbortSignal.timeout(30000)
      });
      
      if (!audioResponse.ok) {
        return {
          success: false,
          error: `Failed to fetch audio: ${audioResponse.status}`,
          retryable: audioResponse.status >= 500
        };
      }
      
      const blob = await audioResponse.blob();
      formData.append("file", blob, "audio.mp4");
    } else if (audioSource.type === "blob") {
      formData.append("file", audioSource.data as Blob, "audio.mp4");
    } else {
      // Base64 - convert to blob
      const base64Data = audioSource.data as string;
      const byteCharacters = atob(base64Data.split(",")[1] || base64Data);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: audioSource.mimeType || "audio/mp4" });
      formData.append("file", blob, "audio.mp4");
    }

    formData.append("model", "whisper-1");
    
    if (options.language) {
      formData.append("language", options.language);
    }
    
    if (options.prompt) {
      formData.append("prompt", options.prompt);
    }
    
    // Request verbose JSON to get timestamps
    formData.append("response_format", options.responseFormat || "verbose_json");
    formData.append("timestamp_granularities[]", "word");
    formData.append("timestamp_granularities[]", "segment");

    const response = await fetch(WHISPER_API_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`
      },
      body: formData,
      signal: AbortSignal.timeout(120000) // 2 minute timeout for large files
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: { message: "Unknown error" } }));
      const errorMessage = errorData.error?.message || `Whisper API error: ${response.status}`;
      
      captureMessage("Whisper transcription failed", {
        status: response.status,
        error: errorMessage
      });

      return {
        success: false,
        error: errorMessage,
        retryable: response.status >= 500 || response.status === 429
      };
    }

    const data = await response.json() as {
      text: string;
      language?: string;
      duration?: number;
      segments?: Array<{
        id: number;
        seek: number;
        start: number;
        end: number;
        text: string;
      }>;
      words?: Array<{
        word: string;
        start: number;
        end: number;
      }>;
    };

    // Convert to our segment format
    const segments: TranscriptSegment[] = (data.segments || []).map((seg, index) => ({
      id: `whisper-seg-${index}`,
      text: seg.text.trim(),
      startSeconds: seg.start,
      durationSeconds: seg.end - seg.start
    }));

    captureMessage("Whisper transcription successful", {
      language: data.language,
      duration: data.duration,
      segmentCount: segments.length
    });

    return {
      success: true,
      transcript: data.text,
      segments,
      language: data.language || "en",
      durationSeconds: data.duration || 0
    };
  } catch (error) {
    const isTimeout = error instanceof Error && error.name === "TimeoutError";
    const errorMessage = error instanceof Error ? error.message : "Unknown transcription error";
    
    captureError(error, {
      action: "whisper_transcription",
      sourceType: audioSource.type
    });

    return {
      success: false,
      error: isTimeout ? "Transcription timed out" : errorMessage,
      retryable: isTimeout
    };
  }
};

/**
 * Extract audio URL from YouTube video
 * Note: This requires a third-party service as YouTube doesn't expose direct audio URLs
 */
export const extractYouTubeAudioUrl = async (videoId: string): Promise<string | null> => {
  // In production, you'd use a service like:
  // - RapidAPI YouTube Audio endpoints
  // - yt-dlp API service
  // - Self-hosted extraction service
  
  // For now, return null to indicate we can't extract audio client-side
  return null;
};

/**
 * Check if Whisper transcription is available
 */
export const isWhisperAvailable = (): boolean => {
  return Boolean(process.env.OPENAI_API_KEY || appEnv.openAiApiKey);
};

/**
 * Transcribe YouTube video using Whisper
 * This is a convenience wrapper for the full pipeline
 */
export const transcribeYouTubeVideo = async (
  videoId: string,
  options: {
    language?: string;
    recipeHint?: boolean; // Add recipe-specific prompt
  } = {}
): Promise<WhisperTranscriptionResult> => {
  const audioUrl = await extractYouTubeAudioUrl(videoId);
  
  if (!audioUrl) {
    return {
      success: false,
      error: "Audio extraction not available client-side. Use server-side processing.",
      retryable: false
    };
  }

  const prompt = options.recipeHint 
    ? "This is a cooking tutorial. Transcribe the recipe instructions and ingredient mentions."
    : undefined;

  return transcribeWithWhisper(
    { type: "url", data: audioUrl },
    { language: options.language, prompt }
  );
};

/**
 * Mock transcription for testing/development
 */
export const mockWhisperTranscription = async (
  videoId: string
): Promise<WhisperTranscriptionResult> => {
  // Simulate API delay
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  return {
    success: true,
    transcript: "Welcome to this cooking tutorial. First, we'll chop the onions and garlic. Then heat some olive oil in a pan. Add the onions and sauté for five minutes until translucent.",
    segments: [
      {
        id: "whisper-seg-0",
        text: "Welcome to this cooking tutorial.",
        startSeconds: 0,
        durationSeconds: 3
      },
      {
        id: "whisper-seg-1",
        text: "First, we'll chop the onions and garlic.",
        startSeconds: 3,
        durationSeconds: 4
      },
      {
        id: "whisper-seg-2",
        text: "Then heat some olive oil in a pan.",
        startSeconds: 7,
        durationSeconds: 3
      },
      {
        id: "whisper-seg-3",
        text: "Add the onions and sauté for five minutes until translucent.",
        startSeconds: 10,
        durationSeconds: 5
      }
    ],
    language: "en",
    durationSeconds: 15
  };
};
