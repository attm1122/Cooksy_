import { trackEvent } from "@/lib/analytics";
import type { SourcePlatform } from "@/features/recipes/types";
import type { ExtractionError } from "./types";

export type ExtractionMetrics = {
  totalAttempts: number;
  successful: number;
  failed: number;
  cached: number;
  byPlatform: Record<SourcePlatform, PlatformMetrics>;
  byErrorType: Record<string, number>;
  averageDurationMs: number;
  p95DurationMs: number;
};

type PlatformMetrics = {
  attempts: number;
  successful: number;
  failed: number;
  cached: number;
  averageDurationMs: number;
  averageSignalCount: number;
};

type ExtractionEvent = {
  url: string;
  platform: SourcePlatform;
  success: boolean;
  durationMs: number;
  errorType?: string;
  signalCount?: number;
  extractionSource: string;
  timestamp: number;
};

// In-memory metrics storage (in production, use a proper metrics service)
class ExtractionAnalytics {
  private events: ExtractionEvent[] = [];
  private maxEvents = 1000; // Keep last 1000 events

  recordExtraction(event: Omit<ExtractionEvent, "timestamp">) {
    const fullEvent: ExtractionEvent = {
      ...event,
      timestamp: Date.now()
    };

    this.events.push(fullEvent);
    
    // Trim old events
    if (this.events.length > this.maxEvents) {
      this.events = this.events.slice(-this.maxEvents);
    }

    // Track to analytics service
    trackEvent(event.success ? "extraction_succeeded" : "extraction_failed", {
      platform: event.platform,
      durationMs: event.durationMs,
      extractionSource: event.extractionSource,
      signalCount: event.signalCount,
      errorType: event.errorType
    });
  }

  getMetrics(timeWindowMs: number = 1000 * 60 * 60 * 24): ExtractionMetrics {
    const cutoff = Date.now() - timeWindowMs;
    const recentEvents = this.events.filter(e => e.timestamp >= cutoff);

    const successful = recentEvents.filter(e => e.success);
    const failed = recentEvents.filter(e => !e.success);
    const cached = recentEvents.filter(e => e.extractionSource === "cache");

    // Platform breakdown
    const byPlatform: Record<SourcePlatform, PlatformMetrics> = {
      youtube: { attempts: 0, successful: 0, failed: 0, cached: 0, averageDurationMs: 0, averageSignalCount: 0 },
      tiktok: { attempts: 0, successful: 0, failed: 0, cached: 0, averageDurationMs: 0, averageSignalCount: 0 },
      instagram: { attempts: 0, successful: 0, failed: 0, cached: 0, averageDurationMs: 0, averageSignalCount: 0 }
    };

    for (const platform of ["youtube", "tiktok", "instagram"] as SourcePlatform[]) {
      const platformEvents = recentEvents.filter(e => e.platform === platform);
      const platformSuccessful = platformEvents.filter(e => e.success);
      
      byPlatform[platform] = {
        attempts: platformEvents.length,
        successful: platformSuccessful.length,
        failed: platformEvents.filter(e => !e.success).length,
        cached: platformEvents.filter(e => e.extractionSource === "cache").length,
        averageDurationMs: platformSuccessful.length > 0
          ? platformSuccessful.reduce((sum, e) => sum + e.durationMs, 0) / platformSuccessful.length
          : 0,
        averageSignalCount: platformSuccessful.length > 0
          ? (platformSuccessful.reduce((sum, e) => sum + (e.signalCount || 0), 0) / platformSuccessful.length)
          : 0
      };
    }

    // Error breakdown
    const byErrorType: Record<string, number> = {};
    for (const event of failed) {
      if (event.errorType) {
        byErrorType[event.errorType] = (byErrorType[event.errorType] || 0) + 1;
      }
    }

    // Duration percentiles
    const durations = successful.map(e => e.durationMs).sort((a, b) => a - b);
    const p95Index = Math.floor(durations.length * 0.95);

    return {
      totalAttempts: recentEvents.length,
      successful: successful.length,
      failed: failed.length,
      cached: cached.length,
      byPlatform,
      byErrorType,
      averageDurationMs: successful.length > 0
        ? successful.reduce((sum, e) => sum + e.durationMs, 0) / successful.length
        : 0,
      p95DurationMs: durations[p95Index] || 0
    };
  }

  getSuccessRate(timeWindowMs?: number): number {
    const metrics = this.getMetrics(timeWindowMs);
    if (metrics.totalAttempts === 0) return 0;
    return (metrics.successful / metrics.totalAttempts) * 100;
  }

  getPlatformSuccessRate(platform: SourcePlatform, timeWindowMs?: number): number {
    const metrics = this.getMetrics(timeWindowMs).byPlatform[platform];
    if (metrics.attempts === 0) return 0;
    return (metrics.successful / metrics.attempts) * 100;
  }

  getRecentErrors(limit: number = 10): Array<{ platform: SourcePlatform; errorType: string; count: number }> {
    const errorMap = new Map<string, { platform: SourcePlatform; errorType: string; count: number }>();
    
    // Get last 100 failed events
    const recentFailed = this.events
      .filter(e => !e.success && e.errorType)
      .slice(-100);

    for (const event of recentFailed) {
      const key = `${event.platform}:${event.errorType}`;
      const existing = errorMap.get(key);
      if (existing) {
        existing.count++;
      } else {
        errorMap.set(key, { 
          platform: event.platform, 
          errorType: event.errorType!, 
          count: 1 
        });
      }
    }

    return Array.from(errorMap.values())
      .sort((a, b) => b.count - a.count)
      .slice(0, limit);
  }

  clear() {
    this.events = [];
  }

  // Get health status for monitoring
  getHealthStatus(): {
    healthy: boolean;
    issues: string[];
    recommendations: string[];
  } {
    const metrics = this.getMetrics();
    const issues: string[] = [];
    const recommendations: string[] = [];

    // Overall success rate
    const overallSuccessRate = this.getSuccessRate();
    if (overallSuccessRate < 70) {
      issues.push(`Low overall success rate: ${overallSuccessRate.toFixed(1)}%`);
      recommendations.push("Check extraction service health and API keys");
    }

    // Platform-specific issues
    for (const platform of ["youtube", "tiktok", "instagram"] as SourcePlatform[]) {
      const platformMetrics = metrics.byPlatform[platform];
      if (platformMetrics.attempts > 0) {
        const successRate = (platformMetrics.successful / platformMetrics.attempts) * 100;
        
        if (successRate < 50) {
          issues.push(`${platform}: Very low success rate (${successRate.toFixed(1)}%)`);
          if (platform === "instagram") {
            recommendations.push("Consider using Instagram Basic Display API instead of scraping");
          } else if (platform === "tiktok") {
            recommendations.push("Enable RapidAPI for better TikTok extraction reliability");
          }
        } else if (successRate < 80) {
          issues.push(`${platform}: Suboptimal success rate (${successRate.toFixed(1)}%)`);
        }

        // Check average duration
        if (platformMetrics.averageDurationMs > 15000) {
          issues.push(`${platform}: Slow extraction (${platformMetrics.averageDurationMs.toFixed(0)}ms avg)`);
          recommendations.push("Consider optimizing extraction timeout settings");
        }
      }
    }

    // Error type analysis
    const errorEntries = Object.entries(metrics.byErrorType);
    for (const [errorType, count] of errorEntries) {
      if (count > 10) {
        issues.push(`Frequent error: ${errorType} (${count} occurrences)`);
      }
    }

    return {
      healthy: issues.length === 0,
      issues,
      recommendations
    };
  }
}

export const extractionAnalytics = new ExtractionAnalytics();

// Convenience function for recording extraction results
export const recordExtractionResult = (params: {
  url: string;
  platform: SourcePlatform;
  success: boolean;
  durationMs: number;
  error?: ExtractionError;
  signalCount?: number;
  extractionSource: string;
}) => {
  extractionAnalytics.recordExtraction({
    url: params.url,
    platform: params.platform,
    success: params.success,
    durationMs: params.durationMs,
    errorType: params.error?.type,
    signalCount: params.signalCount,
    extractionSource: params.extractionSource
  });
};
