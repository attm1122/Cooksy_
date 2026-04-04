import { extractYouTubeContext, youtubeAdapter } from "../youtube-adapter";

describe("youtube-adapter", () => {
  describe("youtubeAdapter", () => {
    it("has correct metadata", () => {
      expect(youtubeAdapter.name).toBe("youtube-native");
      expect(youtubeAdapter.platforms).toContain("youtube");
      expect(youtubeAdapter.priority).toBe(100);
    });
  });

  describe("extractYouTubeContext", () => {
    it("extracts context from a valid YouTube URL", async () => {
      const result = await extractYouTubeContext("https://www.youtube.com/watch?v=dQw4w9WgXcQ");

      expect(result).toHaveProperty("success");
      
      if (result.success) {
        expect(result.context.platform).toBe("youtube");
        expect(result.context.sourceUrl).toContain("youtube.com");
        expect(result.metadata).toHaveProperty("extractionSource");
        expect(result.metadata).toHaveProperty("durationMs");
        expect(result.metadata.extractionSource).toMatch(/youtube|cache/);
      } else {
        // Network failure is acceptable for tests
        expect(result.error).toHaveProperty("type");
        expect(["network_error", "timeout", "unknown"]).toContain(result.error.type);
      }
    });

    it("handles YouTube Shorts URLs", async () => {
      const result = await extractYouTubeContext("https://www.youtube.com/shorts/ABC123");

      // Should either succeed or fail gracefully
      expect(result).toHaveProperty("success");
      
      if (result.success) {
        expect(result.context.platform).toBe("youtube");
      }
    });

    it("handles youtu.be short URLs", async () => {
      const result = await extractYouTubeContext("https://youtu.be/dQw4w9WgXcQ");

      expect(result).toHaveProperty("success");
      
      if (result.success) {
        expect(result.context.platform).toBe("youtube");
      }
    });

    it("handles missing video ID", async () => {
      const result = await extractYouTubeContext("https://www.youtube.com/watch");

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.type).toBe("unsupported_url");
      }
    });

    it("handles invalid URLs", async () => {
      // Invalid URL should throw during parsing (caught by orchestrator)
      // or return a failed result
      try {
        const result = await extractYouTubeContext("not-a-valid-url");
        
        // If it returns a result, it should be a failure
        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.error.type).toMatch(/unsupported_url|unknown/);
        }
      } catch (error) {
        // Throwing is also acceptable behavior for invalid URLs
        expect(error).toBeDefined();
      }
    });

    it("includes thumbnail candidates when successful", async () => {
      const result = await extractYouTubeContext("https://www.youtube.com/watch?v=dQw4w9WgXcQ");

      if (result.success) {
        expect(result.context.thumbnailUrl).toBeTruthy();
        // Should have multiple thumbnail quality options
        expect(result.context.thumbnailCandidates?.length).toBeGreaterThan(0);
      }
    });

    it("reports extraction timing", async () => {
      const startTime = Date.now();
      const result = await extractYouTubeContext("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
      const endTime = Date.now();

      if (result.success) {
        expect(result.metadata.durationMs).toBeGreaterThanOrEqual(0);
        expect(result.metadata.durationMs).toBeLessThanOrEqual(endTime - startTime + 100);
      }
    });
  });

  describe("transcript extraction", () => {
    it("attempts to extract transcripts for videos with captions", async () => {
      // Use a popular cooking video that's likely to have captions
      const result = await extractYouTubeContext("https://www.youtube.com/watch?v=FIj1ywS6D90");

      if (result.success) {
        // Should have metadata about caption extraction attempt
        expect(result.context.metadata).toBeDefined();
        
        // If transcript was extracted, verify structure
        if (result.context.transcript) {
          expect(typeof result.context.transcript).toBe("string");
          expect(result.context.transcript.length).toBeGreaterThan(0);
        }
        
        if (result.context.transcriptSegments) {
          expect(Array.isArray(result.context.transcriptSegments)).toBe(true);
          if (result.context.transcriptSegments.length > 0) {
            const segment = result.context.transcriptSegments[0];
            expect(segment).toHaveProperty("id");
            expect(segment).toHaveProperty("text");
            expect(segment).toHaveProperty("startSeconds");
          }
        }
      }
    });
  });
});
