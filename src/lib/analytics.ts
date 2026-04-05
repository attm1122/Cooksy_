import { appEnv } from "./env";

export type AnalyticsEventName =
  | "app_bootstrapped"
  | "auth_session_ready"
  | "auth_session_failed"
  | "auth_code_requested"
  | "onboarding_completed"
  | "recipes_hydrated"
  | "books_hydrated"
  | "recipe_import_started"
  | "recipe_import_progressed"
  | "recipe_import_completed"
  | "recipe_import_resumed_completed"
  | "recipe_import_failed"
  | "recipe_import_retried"
  | "pending_imports_hydrated"
  | "recipe_updated"
  | "recipe_book_created"
  | "recipe_added_to_book"
  | "recipe_removed_from_book"
  | "subscription_purchase_started"
  | "extraction_succeeded"
  | "extraction_failed";

export type AnalyticsPayload = Record<string, string | number | boolean | null | undefined | Record<string, unknown>>;

type AnalyticsClient = {
  track: (event: AnalyticsEventName, payload?: AnalyticsPayload) => void;
  identify: (userId: string, traits?: Record<string, unknown>) => void;
  reset: () => void;
};

// PostHog configuration
const POSTHOG_API_KEY = process.env.EXPO_PUBLIC_POSTHOG_API_KEY || appEnv.posthogApiKey;
const POSTHOG_HOST = process.env.EXPO_PUBLIC_POSTHOG_HOST || "https://app.posthog.com";

// Console fallback client
const consoleClient: AnalyticsClient = {
  track(event, payload) {
    if (__DEV__) {
      console.info(`[analytics] ${event}`, payload ?? {});
    }
  },
  identify(userId, traits) {
    if (__DEV__) {
      console.info(`[analytics] identify ${userId}`, traits ?? {});
    }
  },
  reset() {
    if (__DEV__) {
      console.info("[analytics] reset");
    }
  }
};

// PostHog client
class PostHogClient implements AnalyticsClient {
  private apiKey: string;
  private host: string;
  private userId: string | null = null;
  private queue: Array<{ type: string; payload: AnalyticsPayload }> = [];
  private flushInterval: ReturnType<typeof setInterval> | null = null;

  constructor(apiKey: string, host: string) {
    this.apiKey = apiKey;
    this.host = host;
    this.startFlushInterval();
  }

  private startFlushInterval() {
    // Flush queue every 30 seconds
    this.flushInterval = setInterval(() => {
      this.flush();
    }, 30000);
  }

  private async flush() {
    if (this.queue.length === 0) return;

    const events = [...this.queue];
    this.queue = [];

    try {
      const response = await fetch(`${this.host}/capture/`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${this.apiKey}`
        },
        body: JSON.stringify({
          api_key: this.apiKey,
          batch: events.map((e) => ({
            event: e.type,
            properties: {
              ...e.payload,
              distinct_id: this.userId || "anonymous",
              $lib: "cooksy-mobile",
              $lib_version: "1.0.0"
            },
            timestamp: new Date().toISOString()
          }))
        })
      });

      if (!response.ok) {
        // Re-queue failed events
        this.queue.unshift(...events);
      }
    } catch (error) {
      // Re-queue failed events
      this.queue.unshift(...events);
      if (__DEV__) {
        console.error("[analytics] Failed to flush events:", error);
      }
    }
  }

  track(event: AnalyticsEventName, payload?: AnalyticsPayload) {
    this.queue.push({ type: event, payload: payload ?? {} });
    
    // Flush immediately if queue gets large
    if (this.queue.length >= 10) {
      void this.flush();
    }

    if (__DEV__) {
      console.info(`[analytics] ${event}`, payload ?? {});
    }
  }

  identify(userId: string, traits?: Record<string, unknown>) {
    this.userId = userId;
    this.queue.push({
      type: "$identify",
      payload: {
        distinct_id: userId,
        $set: traits ?? {}
      }
    });

    if (__DEV__) {
      console.info(`[analytics] identify ${userId}`, traits ?? {});
    }
  }

  reset() {
    this.userId = null;
    this.queue = [];

    if (__DEV__) {
      console.info("[analytics] reset");
    }
  }

  destroy() {
    if (this.flushInterval) {
      clearInterval(this.flushInterval);
    }
    void this.flush();
  }
}

// Initialize the appropriate client
let analyticsClient: AnalyticsClient = consoleClient;

if (POSTHOG_API_KEY && !__DEV__) {
  analyticsClient = new PostHogClient(POSTHOG_API_KEY, POSTHOG_HOST);
}

export const setAnalyticsClient = (client: AnalyticsClient) => {
  analyticsClient = client;
};

export const trackEvent = (event: AnalyticsEventName, payload?: AnalyticsPayload) => {
  analyticsClient.track(event, payload);
};

export const identifyUser = (userId: string, traits?: Record<string, unknown>) => {
  analyticsClient.identify(userId, traits);
};

export const resetAnalytics = () => {
  analyticsClient.reset();
};

export const getAnalyticsClient = () => analyticsClient;
