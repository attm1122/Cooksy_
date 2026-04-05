import { appEnv } from "./env";

export type MonitoringMetadata = Record<string, string | number | boolean | null | undefined>;

type MonitoringClient = {
  captureError: (error: unknown, metadata?: MonitoringMetadata) => string | undefined;
  captureMessage: (message: string, metadata?: MonitoringMetadata) => string | undefined;
  captureException: (error: Error, metadata?: MonitoringMetadata) => string | undefined;
  setUser: (userId: string | null, metadata?: MonitoringMetadata) => void;
  setTag: (key: string, value: string) => void;
  addBreadcrumb: (message: string, category?: string, metadata?: MonitoringMetadata) => void;
};

// Sentry configuration
const SENTRY_DSN = process.env.EXPO_PUBLIC_SENTRY_DSN || appEnv.sentryDsn;

// Console fallback client
const consoleClient: MonitoringClient = {
  captureError(error, metadata) {
    console.error("[monitoring]", error, metadata ?? {});
    return undefined;
  },
  captureMessage(message, metadata) {
    if (__DEV__) {
      console.warn(`[monitoring] ${message}`, metadata ?? {});
    }
    return undefined;
  },
  captureException(error, metadata) {
    console.error("[monitoring] Exception:", error, metadata ?? {});
    return undefined;
  },
  setUser(userId, metadata) {
    if (__DEV__) {
      console.info(`[monitoring] Set user: ${userId}`, metadata ?? {});
    }
  },
  setTag(key, value) {
    if (__DEV__) {
      console.info(`[monitoring] Tag: ${key}=${value}`);
    }
  },
  addBreadcrumb(message, category, metadata) {
    if (__DEV__) {
      console.info(`[monitoring] Breadcrumb: [${category}] ${message}`, metadata ?? {});
    }
  }
};

// Sentry client
class SentryClient implements MonitoringClient {
  private dsn: string;
  private userId: string | null = null;
  private tags: Map<string, string> = new Map();
  private breadcrumbs: Array<{ message: string; category?: string; metadata?: MonitoringMetadata; timestamp: string }> = [];

  constructor(dsn: string) {
    this.dsn = dsn;
  }

  private parseDsn() {
    try {
      const url = new URL(this.dsn);
      const projectId = url.pathname.replace("/", "");
      const key = url.username;
      const host = `${url.protocol}//${url.host}`;
      return { key, projectId, host };
    } catch {
      return null;
    }
  }

  private async sendEvent(event: unknown) {
    const parsed = this.parseDsn();
    if (!parsed) return;

    try {
      await fetch(`${parsed.host}/api/${parsed.projectId}/store/`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Sentry-Auth": `Sentry sentry_version=7, sentry_key=${parsed.key}, sentry_client=cooksy-mobile/1.0.0`
        },
        body: JSON.stringify(event)
      });
    } catch (error) {
      // Silent fail - can't report errors about error reporting
      if (__DEV__) {
        console.error("[monitoring] Failed to send to Sentry:", error);
      }
    }
  }

  captureError(error: unknown, metadata?: MonitoringMetadata): string | undefined {
    const eventId = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    const errorObj = error instanceof Error ? error : new Error(String(error));
    
    void this.sendEvent({
      event_id: eventId,
      timestamp: new Date().toISOString(),
      platform: "javascript",
      level: "error",
      logger: "cooksy",
      message: {
        formatted: errorObj.message
      },
      exception: {
        values: [{
          type: errorObj.name,
          value: errorObj.message,
          stacktrace: {
            frames: errorObj.stack?.split("\n").map((line) => ({
              function: line.trim()
            })) ?? []
          }
        }]
      },
      user: this.userId ? { id: this.userId } : undefined,
      tags: Object.fromEntries(this.tags),
      extra: metadata,
      breadcrumbs: this.breadcrumbs.slice(-50) // Keep last 50 breadcrumbs
    });

    // Clear breadcrumbs after sending
    this.breadcrumbs = [];

    return eventId;
  }

  captureMessage(message: string, metadata?: MonitoringMetadata): string | undefined {
    const eventId = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

    void this.sendEvent({
      event_id: eventId,
      timestamp: new Date().toISOString(),
      platform: "javascript",
      level: "info",
      logger: "cooksy",
      message: { formatted: message },
      user: this.userId ? { id: this.userId } : undefined,
      tags: Object.fromEntries(this.tags),
      extra: metadata
    });

    return eventId;
  }

  captureException(error: Error, metadata?: MonitoringMetadata): string | undefined {
    return this.captureError(error, metadata);
  }

  setUser(userId: string | null, metadata?: MonitoringMetadata) {
    this.userId = userId;
    if (__DEV__ && userId) {
      console.info(`[monitoring] Set user: ${userId}`, metadata ?? {});
    }
  }

  setTag(key: string, value: string) {
    this.tags.set(key, value);
  }

  addBreadcrumb(message: string, category?: string, metadata?: MonitoringMetadata) {
    this.breadcrumbs.push({
      message,
      category,
      metadata,
      timestamp: new Date().toISOString()
    });

    // Keep only last 100 breadcrumbs
    if (this.breadcrumbs.length > 100) {
      this.breadcrumbs = this.breadcrumbs.slice(-100);
    }
  }
}

// Initialize the appropriate client
let monitoringClient: MonitoringClient = consoleClient;

if (SENTRY_DSN && !__DEV__) {
  monitoringClient = new SentryClient(SENTRY_DSN);
}

export const setMonitoringClient = (client: MonitoringClient) => {
  monitoringClient = client;
};

export const captureError = (error: unknown, metadata?: MonitoringMetadata): string | undefined => {
  return monitoringClient.captureError(error, metadata);
};

export const captureMessage = (message: string, metadata?: MonitoringMetadata): string | undefined => {
  return monitoringClient.captureMessage(message, metadata);
};

export const captureException = (error: Error, metadata?: MonitoringMetadata): string | undefined => {
  return monitoringClient.captureException(error, metadata);
};

export const setMonitoringUser = (userId: string | null, metadata?: MonitoringMetadata) => {
  monitoringClient.setUser(userId, metadata);
};

export const setMonitoringTag = (key: string, value: string) => {
  monitoringClient.setTag(key, value);
};

export const addBreadcrumb = (message: string, category?: string, metadata?: MonitoringMetadata) => {
  monitoringClient.addBreadcrumb(message, category, metadata);
};

export const getMonitoringClient = () => monitoringClient;
