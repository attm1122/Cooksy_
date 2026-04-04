type AnalyticsEventName =
  | "app_bootstrapped"
  | "auth_session_ready"
  | "auth_session_failed"
  | "recipes_hydrated"
  | "books_hydrated"
  | "recipe_import_started"
  | "recipe_import_progressed"
  | "recipe_import_completed"
  | "recipe_import_failed"
  | "recipe_import_retried"
  | "recipe_updated"
  | "recipe_book_created"
  | "recipe_added_to_book"
  | "recipe_removed_from_book";

type AnalyticsPayload = Record<string, string | number | boolean | null | undefined>;

type AnalyticsClient = {
  track: (event: AnalyticsEventName, payload?: AnalyticsPayload) => void;
};

const defaultClient: AnalyticsClient = {
  track(event, payload) {
    if (__DEV__) {
      console.info(`[analytics] ${event}`, payload ?? {});
    }
  }
};

let analyticsClient: AnalyticsClient = defaultClient;

export const setAnalyticsClient = (client: AnalyticsClient) => {
  analyticsClient = client;
};

export const trackEvent = (event: AnalyticsEventName, payload?: AnalyticsPayload) => {
  analyticsClient.track(event, payload);
};
