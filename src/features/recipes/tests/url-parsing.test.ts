import {
  detectPlatformFromUrl,
  parseInstagramUrl,
  parseTikTokUrl,
  parseYouTubeUrl
} from "@/features/recipes/lib/platform";
import { InvalidRecipeUrlError, UnsupportedPlatformError } from "@/features/recipes/lib/errors";

describe("recipe URL parsing", () => {
  it("detects valid YouTube URLs", () => {
    expect(detectPlatformFromUrl("https://www.youtube.com/watch?v=cooksy123")).toBe("youtube");
    expect(parseYouTubeUrl("https://youtu.be/cooksy123").videoId).toBe("cooksy123");
  });

  it("detects valid TikTok URLs", () => {
    expect(detectPlatformFromUrl("https://www.tiktok.com/@cooksy/video/123456789")).toBe("tiktok");
    expect(parseTikTokUrl("https://www.tiktok.com/@cooksy/video/123456789")).toMatchObject({
      creatorHandle: "cooksy",
      videoId: "123456789"
    });
  });

  it("detects valid Instagram URLs", () => {
    expect(detectPlatformFromUrl("https://www.instagram.com/reel/CooksyPasta/")).toBe("instagram");
    expect(parseInstagramUrl("https://www.instagram.com/reel/CooksyPasta/").mediaCode).toBe("CooksyPasta");
  });

  it("rejects malformed URLs", () => {
    expect(() => parseYouTubeUrl("not-a-url")).toThrow(InvalidRecipeUrlError);
  });

  it("rejects unsupported URLs", () => {
    expect(() => detectPlatformFromUrl("https://example.com/recipe")).toThrow(UnsupportedPlatformError);
  });
});

