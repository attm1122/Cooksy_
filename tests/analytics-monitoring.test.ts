import { setAnalyticsClient, trackEvent } from "@/lib/analytics";
import { captureError, captureMessage, setMonitoringClient } from "@/lib/monitoring";

describe("analytics and monitoring seams", () => {
  it("forwards analytics events to the configured client", () => {
    const track = jest.fn();

    setAnalyticsClient({ track, identify: jest.fn(), reset: jest.fn() });
    trackEvent("recipe_import_started", { jobId: "job-123" });

    expect(track).toHaveBeenCalledWith("recipe_import_started", { jobId: "job-123" });
  });

  it("forwards monitoring calls to the configured client", () => {
    const client = {
      captureError: jest.fn(),
      captureException: jest.fn(),
      captureMessage: jest.fn(),
      setUser: jest.fn(),
      setTag: jest.fn(),
      addBreadcrumb: jest.fn()
    };

    setMonitoringClient(client);
    captureMessage("Import failed", { jobId: "job-123" });
    captureError(new Error("boom"), { action: "test" });

    expect(client.captureMessage).toHaveBeenCalledWith("Import failed", { jobId: "job-123" });
    expect(client.captureError).toHaveBeenCalled();
  });
});
