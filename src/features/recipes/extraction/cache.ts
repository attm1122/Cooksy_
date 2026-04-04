import type { RawRecipeContext } from "@/features/recipes/types";
import type { ExtractionCache } from "./types";

// In-memory cache for extracted contexts
// In production, this could be backed by Redis or AsyncStorage
class MemoryExtractionCache implements ExtractionCache {
  private cache = new Map<string, { context: RawRecipeContext; expiresAt: number }>();
  private defaultTtlMs = 1000 * 60 * 60; // 1 hour default

  get(url: string): RawRecipeContext | undefined {
    const entry = this.cache.get(url);
    if (!entry) return undefined;
    
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(url);
      return undefined;
    }
    
    return entry.context;
  }

  set(url: string, context: RawRecipeContext, ttlMs = this.defaultTtlMs): void {
    this.cache.set(url, {
      context,
      expiresAt: Date.now() + ttlMs
    });
  }

  clear(): void {
    this.cache.clear();
  }

  // For debugging/monitoring
  size(): number {
    return this.cache.size;
  }

  // Clean up expired entries
  cleanup(): number {
    const now = Date.now();
    let cleaned = 0;
    for (const [url, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        this.cache.delete(url);
        cleaned++;
      }
    }
    return cleaned;
  }
}

// Platform-specific rate limiters
class PlatformRateLimiter {
  private attempts = new Map<string, number[]>();
  private limits = {
    youtube: { maxRequests: 30, windowMs: 60000 }, // 30 req/min
    tiktok: { maxRequests: 10, windowMs: 60000 },   // 10 req/min  
    instagram: { maxRequests: 10, windowMs: 60000 } // 10 req/min
  };

  canProceed(platform: string): boolean {
    const limit = this.limits[platform as keyof typeof this.limits];
    if (!limit) return true;

    const now = Date.now();
    const platformAttempts = this.attempts.get(platform) || [];
    
    // Clean old attempts outside window
    const recentAttempts = platformAttempts.filter(t => now - t < limit.windowMs);
    this.attempts.set(platform, recentAttempts);

    return recentAttempts.length < limit.maxRequests;
  }

  recordAttempt(platform: string): void {
    const attempts = this.attempts.get(platform) || [];
    attempts.push(Date.now());
    this.attempts.set(platform, attempts);
  }

  getWaitTimeMs(platform: string): number {
    const limit = this.limits[platform as keyof typeof this.limits];
    if (!limit) return 0;

    const attempts = this.attempts.get(platform) || [];
    if (attempts.length === 0) return 0;

    const oldestAttempt = Math.min(...attempts);
    const windowExpiry = oldestAttempt + limit.windowMs;
    const waitTime = windowExpiry - Date.now();

    return Math.max(0, waitTime);
  }

  getStatus(platform: string): { remaining: number; resetInMs: number } {
    const limit = this.limits[platform as keyof typeof this.limits];
    if (!limit) return { remaining: Infinity, resetInMs: 0 };

    const now = Date.now();
    const attempts = this.attempts.get(platform) || [];
    const recentAttempts = attempts.filter(t => now - t < limit.windowMs);
    
    return {
      remaining: Math.max(0, limit.maxRequests - recentAttempts.length),
      resetInMs: attempts.length > 0 ? this.getWaitTimeMs(platform) : 0
    };
  }
}

export const extractionCache = new MemoryExtractionCache();
export const rateLimiter = new PlatformRateLimiter();
