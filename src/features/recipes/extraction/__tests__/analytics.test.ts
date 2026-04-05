import { extractionAnalytics, recordExtractionResult } from "../analytics";
import type { SourcePlatform } from "@/features/recipes/types";

describe("extraction analytics", () => {
  beforeEach(() => {
    extractionAnalytics.clear();
  });

  describe("recordExtractionResult", () => {
    it("records successful extraction", () => {
      recordExtractionResult({
        url: "https://youtube.com/watch?v=test",
        platform: "youtube" as SourcePlatform,
        success: true,
        durationMs: 1500,
        signalCount: 10,
        extractionSource: "youtube-adapter"
      });

      const metrics = extractionAnalytics.getMetrics();
      expect(metrics.totalAttempts).toBe(1);
      expect(metrics.successful).toBe(1);
      expect(metrics.failed).toBe(0);
    });

    it("records failed extraction", () => {
      recordExtractionResult({
        url: "https://tiktok.com/@user/video/123",
        platform: "tiktok" as SourcePlatform,
        success: false,
        durationMs: 500,
        error: { type: "network_error", message: "Connection failed", retryable: true },
        extractionSource: "failed"
      });

      const metrics = extractionAnalytics.getMetrics();
      expect(metrics.totalAttempts).toBe(1);
      expect(metrics.successful).toBe(0);
      expect(metrics.failed).toBe(1);
      expect(metrics.byErrorType["network_error"]).toBe(1);
    });

    it("tracks platform-specific metrics", () => {
      // YouTube success
      recordExtractionResult({
        url: "https://youtube.com/watch?v=1",
        platform: "youtube" as SourcePlatform,
        success: true,
        durationMs: 1000,
        signalCount: 8,
        extractionSource: "youtube-adapter"
      });

      // TikTok failure
      recordExtractionResult({
        url: "https://tiktok.com/@user/video/1",
        platform: "tiktok" as SourcePlatform,
        success: false,
        durationMs: 500,
        error: { type: "rate_limited", message: "Rate limit exceeded" },
        extractionSource: "failed"
      });

      const metrics = extractionAnalytics.getMetrics();
      expect(metrics.byPlatform.youtube.attempts).toBe(1);
      expect(metrics.byPlatform.youtube.successful).toBe(1);
      expect(metrics.byPlatform.tiktok.attempts).toBe(1);
      expect(metrics.byPlatform.tiktok.failed).toBe(1);
    });

    it("tracks cached results", () => {
      recordExtractionResult({
        url: "https://youtube.com/watch?v=cached",
        platform: "youtube" as SourcePlatform,
        success: true,
        durationMs: 0,
        signalCount: 5,
        extractionSource: "cache"
      });

      const metrics = extractionAnalytics.getMetrics();
      expect(metrics.cached).toBe(1);
    });
  });

  describe("getSuccessRate", () => {
    it("calculates overall success rate", () => {
      // 3 successes
      for (let i = 0; i < 3; i++) {
        recordExtractionResult({
          url: `https://youtube.com/watch?v=${i}`,
          platform: "youtube" as SourcePlatform,
          success: true,
          durationMs: 1000,
          extractionSource: "youtube-adapter"
        });
      }

      // 1 failure
      recordExtractionResult({
        url: "https://youtube.com/watch?v=fail",
        platform: "youtube" as SourcePlatform,
        success: false,
        durationMs: 500,
        error: { type: "timeout", message: "Request timed out" },
        extractionSource: "failed"
      });

      expect(extractionAnalytics.getSuccessRate()).toBe(75); // 3/4 = 75%
    });

    it("returns 0 when no attempts", () => {
      expect(extractionAnalytics.getSuccessRate()).toBe(0);
    });
  });

  describe("getPlatformSuccessRate", () => {
    it("calculates platform-specific success rate", () => {
      // YouTube: 2/2 success
      recordExtractionResult({
        url: "https://youtube.com/watch?v=1",
        platform: "youtube" as SourcePlatform,
        success: true,
        durationMs: 1000,
        extractionSource: "youtube-adapter"
      });

      // TikTok: 0/1 success
      recordExtractionResult({
        url: "https://tiktok.com/@user/video/1",
        platform: "tiktok" as SourcePlatform,
        success: false,
        durationMs: 500,
        error: { type: "network_error", message: "Failed", retryable: true },
        extractionSource: "failed"
      });

      expect(extractionAnalytics.getPlatformSuccessRate("youtube")).toBe(100);
      expect(extractionAnalytics.getPlatformSuccessRate("tiktok")).toBe(0);
      expect(extractionAnalytics.getPlatformSuccessRate("instagram")).toBe(0);
    });
  });

  describe("getHealthStatus", () => {
    it("returns healthy when success rates are good", () => {
      for (let i = 0; i < 10; i++) {
        recordExtractionResult({
          url: `https://youtube.com/watch?v=${i}`,
          platform: "youtube" as SourcePlatform,
          success: true,
          durationMs: 1000,
          extractionSource: "youtube-adapter"
        });
      }

      const health = extractionAnalytics.getHealthStatus();
      expect(health.healthy).toBe(true);
      expect(health.issues).toHaveLength(0);
    });

    it("identifies low success rates", () => {
      // Add many failures
      for (let i = 0; i < 10; i++) {
        recordExtractionResult({
          url: `https://tiktok.com/@user/video/${i}`,
          platform: "tiktok" as SourcePlatform,
          success: false,
          durationMs: 500,
          error: { type: "network_error", message: "Failed", retryable: true },
          extractionSource: "failed"
        });
      }

      const health = extractionAnalytics.getHealthStatus();
      expect(health.healthy).toBe(false);
      expect(health.issues.length).toBeGreaterThan(0);
      expect(health.recommendations.length).toBeGreaterThan(0);
    });

    it("identifies slow extractions", () => {
      recordExtractionResult({
        url: "https://youtube.com/watch?v=slow",
        platform: "youtube" as SourcePlatform,
        success: true,
        durationMs: 20000, // Very slow
        extractionSource: "youtube-adapter"
      });

      const health = extractionAnalytics.getHealthStatus();
      expect(health.issues.some(i => i.includes("Slow"))).toBe(true);
    });
  });

  describe("getRecentErrors", () => {
    it("returns most common recent errors", () => {
      // Multiple network errors
      for (let i = 0; i < 5; i++) {
        recordExtractionResult({
          url: `https://youtube.com/watch?v=${i}`,
          platform: "youtube" as SourcePlatform,
          success: false,
          durationMs: 500,
          error: { type: "network_error", message: "Failed", retryable: true },
          extractionSource: "failed"
        });
      }

      // Few timeout errors
      for (let i = 0; i < 2; i++) {
        recordExtractionResult({
          url: `https://tiktok.com/@user/video/${i}`,
          platform: "tiktok" as SourcePlatform,
          success: false,
          durationMs: 30000,
          error: { type: "timeout", message: "Timeout" },
          extractionSource: "failed"
        });
      }

      const errors = extractionAnalytics.getRecentErrors(10);
      expect(errors[0].errorType).toBe("network_error");
      expect(errors[0].count).toBe(5);
      expect(errors[1].errorType).toBe("timeout");
      expect(errors[1].count).toBe(2);
    });
  });

  describe("time window filtering", () => {
    it("respects time window for metrics", () => {
      // This test verifies the API works
      // In real usage, events would have different timestamps
      const metrics = extractionAnalytics.getMetrics(1000 * 60 * 60); // 1 hour
      expect(metrics).toHaveProperty("totalAttempts");
      expect(metrics).toHaveProperty("byPlatform");
      expect(metrics).toHaveProperty("byErrorType");
    });
  });
});
