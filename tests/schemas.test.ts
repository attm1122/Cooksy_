import { createProfileSchema, verifyProfileCodeSchema } from "@/lib/auth-schemas";
import { importRecipeSchema, recipeSchema } from "@/lib/schemas";
import { mockRecipes } from "@/mocks/recipes";

describe("recipeSchema", () => {
  it("accepts a valid mocked recipe", () => {
    expect(() => recipeSchema.parse(mockRecipes[0])).not.toThrow();
  });

  it("rejects an invalid import url", () => {
    expect(() => importRecipeSchema.parse({ sourceUrl: "not-a-url" })).toThrow();
  });

  it("rejects unsupported source platforms", () => {
    expect(() => importRecipeSchema.parse({ sourceUrl: "https://example.com/watch?v=recipe" })).toThrow(
      "Cooksy currently supports YouTube, TikTok, and Instagram recipe links"
    );
  });

  it("accepts supported social share links", () => {
    expect(() => importRecipeSchema.parse({ sourceUrl: "https://www.youtube.com/watch?v=cooksy123" })).not.toThrow();
    expect(() => importRecipeSchema.parse({ sourceUrl: "https://www.tiktok.com/@cooksy/video/123456789" })).not.toThrow();
    expect(() => importRecipeSchema.parse({ sourceUrl: "https://www.instagram.com/reel/CooksyPasta/" })).not.toThrow();
  });
});

describe("profile auth schemas", () => {
  it("accepts a valid profile creation payload", () => {
    expect(() =>
      createProfileSchema.parse({
        fullName: "Aubrey Mazinyi",
        email: "aubrey@example.com"
      })
    ).not.toThrow();
  });

  it("rejects invalid profile creation payloads", () => {
    expect(() =>
      createProfileSchema.parse({
        fullName: "A",
        email: "not-an-email"
      })
    ).toThrow();
  });

  it("accepts a 6 digit verification code", () => {
    expect(() => verifyProfileCodeSchema.parse({ token: "123456" })).not.toThrow();
  });

  it("rejects malformed verification codes", () => {
    expect(() => verifyProfileCodeSchema.parse({ token: "12ab" })).toThrow();
  });
});
