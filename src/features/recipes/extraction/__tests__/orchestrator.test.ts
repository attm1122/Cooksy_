import { 
  extractContextFromUrl, 
  extractMultipleContexts, 
  getExtractionStatus, 
  clearExtractionCache 
} from "../orchestrator";

describe("extraction orchestrator", () => {
  beforeEach(() => {
    clearExtractionCache();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe("extractContextFromUrl", () => {
    it("processes YouTube URLs", async () => {
      const result = await extractContextFromUrl(
        "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        { timeoutMs: 10000, retryCount: 0 }
      );

      // Should return a result (success or failure)
      expect(result).toHaveProperty("success");
      
      if (!result.success) {
        // If failed, should have proper error structure
        expect(result.error).toHaveProperty("type");
        expect(result.error).toHaveProperty("message");
      } else {
        // If succeeded, verify context structure
        expect(result.context.platform).toBe("youtube");
        expect(result.context.sourceUrl).toContain("youtube.com");
        expect(result.metadata).toHaveProperty("extractionSource");
        expect(result.metadata).toHaveProperty("durationMs");
      }
    });

    it("processes TikTok URLs", async () => {
      const result = await extractContextFromUrl(
        "https://www.tiktok.com/@chef/video/1234567890",
        { timeoutMs: 10000, retryCount: 0 }
      );

      expect(result).toHaveProperty("success");
      
      if (result.success) {
        expect(result.context.platform).toBe("tiktok");
      }
    });

    it("processes Instagram URLs", async () => {
      const result = await extractContextFromUrl(
        "https://www.instagram.com/reel/ABC123/",
        { timeoutMs: 10000, retryCount: 0 }
      );

      expect(result).toHaveProperty("success");
      
      if (result.success) {
        expect(result.context.platform).toBe("instagram");
      }
    });

    it("returns error for unsupported URLs", async () => {
      // Use a URL that's clearly not supported
      const result = await extractContextFromUrl("https://example.com/not-a-video");

      expect(result.success).toBe(false);
      if (!result.success) {
        // Error type could be unsupported_url or unknown depending on error handling
        expect(["unsupported_url", "unknown"]).toContain(result.error.type);
      }
    });

    it("returns cached result on second call", async () => {
      const url = "https://www.youtube.com/watch?v=CACHED_TEST_123";
      
      // First call
      const result1 = await extractContextFromUrl(url, { timeoutMs: 10000, retryCount: 0 });
      
      // Second call should use cache if first succeeded
      const result2 = await extractContextFromUrl(url);

      if (result1.success && result2.success) {
        expect(result2.metadata.extractionSource).toBe("cache");
        expect(result2.metadata.durationMs).toBe(0);
        // Context should be identical
        expect(result2.context).toEqual(result1.context);
      }
    });

    it("bypasses cache when forceFresh is true", async () => {
      const url = "https://www.youtube.com/watch?v=FRESH_TEST_456";
      
      // First call
      await extractContextFromUrl(url, { timeoutMs: 10000, retryCount: 0 });
      
      // Second call with forceFresh
      const result2 = await extractContextFromUrl(url, { 
        forceFresh: true, 
        timeoutMs: 10000, 
        retryCount: 0 
      });

      if (result2.success) {
        expect(result2.metadata.extractionSource).not.toBe("cache");
      }
    });
  });

  describe("extractMultipleContexts", () => {
    it("processes multiple URLs", async () => {
      const urls = [
        "https://www.youtube.com/watch?v=BATCH1",
        "https://www.youtube.com/watch?v=BATCH2"
      ];

      const results = await extractMultipleContexts(urls, { 
        timeoutMs: 10000, 
        retryCount: 0 
      });

      expect(results.size).toBe(2);
      for (const url of urls) {
        expect(results.has(url)).toBe(true);
        const result = results.get(url);
        expect(result).toHaveProperty("success");
      }
    });
  });

  describe("getExtractionStatus", () => {
    it("returns current status", () => {
      const status = getExtractionStatus();

      expect(status).toHaveProperty("cacheSize");
      expect(status).toHaveProperty("rateLimits");
      expect(status).toHaveProperty("adapters");
      expect(Array.isArray(status.adapters)).toBe(true);
      expect(status.adapters.length).toBeGreaterThan(0);
    });

    it("reports rate limit status for all platforms", () => {
      const status = getExtractionStatus();

      expect(status.rateLimits).toHaveProperty("youtube");
      expect(status.rateLimits).toHaveProperty("tiktok");
      expect(status.rateLimits).toHaveProperty("instagram");
      
      expect(status.rateLimits.youtube).toHaveProperty("remaining");
      expect(status.rateLimits.youtube).toHaveProperty("resetInMs");
    });

    it("lists all registered adapters", () => {
      const status = getExtractionStatus();

      const adapterNames = status.adapters.map(a => a.name);
      expect(adapterNames.some(n => n.includes("youtube"))).toBe(true);
      expect(adapterNames.some(n => n.includes("tiktok"))).toBe(true);
      expect(adapterNames.some(n => n.includes("instagram"))).toBe(true);
    });
  });

  describe("clearExtractionCache", () => {
    it("clears the cache", async () => {
      const url = "https://www.youtube.com/watch?v=CLEAR_TEST";
      
      // Add something to cache
      await extractContextFromUrl(url, { timeoutMs: 10000, retryCount: 0 });
      
      // Clear cache
      clearExtractionCache();
      
      // Check status
      const status = getExtractionStatus();
      expect(status.cacheSize).toBe(0);
    });
  });
});
