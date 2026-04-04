type MonitoringMetadata = Record<string, string | number | boolean | null | undefined>;

type MonitoringClient = {
  captureError: (error: unknown, metadata?: MonitoringMetadata) => void;
  captureMessage: (message: string, metadata?: MonitoringMetadata) => void;
};

const defaultClient: MonitoringClient = {
  captureError(error, metadata) {
    console.error("[monitoring]", error, metadata ?? {});
  },
  captureMessage(message, metadata) {
    if (__DEV__) {
      console.warn(`[monitoring] ${message}`, metadata ?? {});
    }
  }
};

let monitoringClient: MonitoringClient = defaultClient;

export const setMonitoringClient = (client: MonitoringClient) => {
  monitoringClient = client;
};

export const captureError = (error: unknown, metadata?: MonitoringMetadata) => {
  monitoringClient.captureError(error, metadata);
};

export const captureMessage = (message: string, metadata?: MonitoringMetadata) => {
  monitoringClient.captureMessage(message, metadata);
};
