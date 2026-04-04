import type { RawRecipeContext, SourcePlatform } from "@/features/recipes/types";

const youtubeContext: RawRecipeContext = {
  sourceUrl: "https://www.youtube.com/watch?v=cooksy-garlic-chicken",
  platform: "youtube",
  title: "Creamy Garlic Chicken Orzo in One Pan",
  creator: "Mila's Kitchen",
  caption:
    "One pan creamy garlic chicken orzo. Sear chicken thighs, build the sauce with garlic and cream, then simmer the orzo until glossy.",
  transcript:
    "Today we're making creamy garlic chicken orzo. Start with six boneless chicken thighs seasoned well. Sear them until golden, then add five cloves of minced garlic. Stir in one cup of orzo, about two cups of chicken stock, and half a cup of cream. Let that simmer for twelve minutes, add parmesan and spinach, then finish with lemon.",
  ocrText: ["6 chicken thighs", "5 garlic cloves", "1 cup orzo", "half cup cream"],
  comments: ["Made this with extra spinach and it worked great.", "I used two cups of stock and it turned out perfectly."],
  metadata: {
    ingredientHints: [
      { name: "Chicken thighs", quantity: "6", unit: "pieces" },
      { name: "Garlic cloves", quantity: "5", unit: "cloves" },
      { name: "Orzo", quantity: "1", unit: "cup" },
      { name: "Chicken stock", quantity: "2", unit: "cups" },
      { name: "Heavy cream", quantity: "1/2", unit: "cup" },
      { name: "Parmesan", quantity: "1/2", unit: "cup", note: "grated" },
      { name: "Baby spinach", quantity: "2", unit: "handfuls" }
    ],
    stepHints: [
      { instruction: "Season and sear the chicken thighs until golden on both sides.", durationMinutes: 8 },
      { instruction: "Cook the garlic briefly, then stir in orzo, stock, and cream.", durationMinutes: 3 },
      { instruction: "Simmer until the orzo is tender, then fold in parmesan and spinach.", durationMinutes: 12 }
    ],
    servingsHint: 4,
    prepTimeMinutesHint: 15,
    cookTimeMinutesHint: 25
  },
  thumbnailUrl: "https://img.youtube.com/vi/cooksy-garlic-chicken/hqdefault.jpg"
};

const tikTokContext: RawRecipeContext = {
  sourceUrl: "https://www.tiktok.com/@ninacooks/video/123456789",
  platform: "tiktok",
  title: "Crispy Hot Honey Salmon Rice Bowl",
  creator: "Nina Cooks",
  caption:
    "Crispy salmon with a hot honey glaze over jasmine rice. Fast, sticky, spicy, and perfect for weeknights.",
  transcript:
    "Cut two salmon fillets into large cubes and season with salt. Roast or air fry until almost crisp. Mix three tablespoons of honey with one tablespoon chili crisp and a splash of soy sauce. Coat the salmon for the last few minutes. Serve it over rice with cucumber and avocado.",
  ocrText: ["2 salmon fillets", "3 tbsp honey", "1 tbsp chili crisp"],
  comments: ["Needed a temperature for the oven!", "I served this with rice and cucumber."],
  metadata: {
    ingredientHints: [
      { name: "Salmon fillets", quantity: "2", unit: "fillets" },
      { name: "Honey", quantity: "3", unit: "tbsp" },
      { name: "Chili crisp", quantity: "1", unit: "tbsp" },
      { name: "Soy sauce", quantity: "1", unit: "splash", inferred: true },
      { name: "Cooked rice", quantity: "2", unit: "cups", note: "for serving", inferred: true }
    ],
    stepHints: [
      { instruction: "Season and roast or air fry the salmon until nearly crisp.", durationMinutes: 12 },
      { instruction: "Whisk together honey, chili crisp, and soy sauce.", durationMinutes: 2 },
      { instruction: "Glaze the salmon, finish cooking, and serve over rice.", durationMinutes: 4 }
    ],
    servingsHint: 2,
    prepTimeMinutesHint: 10,
    cookTimeMinutesHint: 16
  },
  thumbnailUrl: "https://picsum.photos/seed/tiktok-123456789/1280/960"
};

const instagramContext: RawRecipeContext = {
  sourceUrl: "https://www.instagram.com/reel/CooksyTuscanPasta/",
  platform: "instagram",
  title: "One Pan Tuscan Pasta",
  creator: "Luca at Home",
  caption:
    "One pan tuscan pasta with sun-dried tomatoes, cream, spinach, and parmesan. No separate pasta water, just glossy sauce in the pan.",
  transcript:
    "Start by cooking garlic and sun-dried tomatoes in olive oil. Add the pasta right into the pan with stock and cream. Let it cook until tender, then stir through spinach and parmesan. Finish with black pepper and a little chili if you like.",
  ocrText: ["12 oz rigatoni", "3 cups stock", "3/4 cup cream", "spinach + parmesan"],
  comments: ["Need to know how much parmesan!", "Looks like four servings to me."],
  metadata: {
    ingredientHints: [
      { name: "Rigatoni", quantity: "12", unit: "oz" },
      { name: "Sun-dried tomatoes", quantity: "1/2", unit: "cup" },
      { name: "Garlic cloves", quantity: "4", unit: "cloves" },
      { name: "Vegetable stock", quantity: "3", unit: "cups" },
      { name: "Cream", quantity: "3/4", unit: "cup" },
      { name: "Baby spinach", quantity: "2", unit: "handfuls", inferred: true },
      { name: "Parmesan", quantity: null, unit: null, note: "to finish", inferred: true }
    ],
    stepHints: [
      { instruction: "Cook garlic and sun-dried tomatoes until fragrant.", durationMinutes: 4 },
      { instruction: "Add pasta, stock, and cream, then simmer until tender.", durationMinutes: 16 },
      { instruction: "Fold in spinach and parmesan, then season to finish.", durationMinutes: 2 }
    ],
    servingsHint: 4,
    prepTimeMinutesHint: 12,
    cookTimeMinutesHint: 22
  },
  thumbnailUrl: "https://picsum.photos/seed/instagram-CooksyTuscanPasta/1280/960"
};

const genericContexts: Record<SourcePlatform, RawRecipeContext> = {
  youtube: youtubeContext,
  tiktok: tikTokContext,
  instagram: instagramContext
};

export const getMockContextForUrl = (url: string, platform: SourcePlatform): RawRecipeContext => {
  if (url.includes("garlic") || url.includes("chicken") || url.includes("short-form-cooking-demo")) {
    return {
      ...youtubeContext,
      sourceUrl: url
    };
  }

  if (url.includes("salmon") || url.includes("123456789")) {
    return {
      ...tikTokContext,
      sourceUrl: url
    };
  }

  if (url.toLowerCase().includes("tuscan") || url.includes("CooksyTuscanPasta")) {
    return {
      ...instagramContext,
      sourceUrl: url
    };
  }

  return {
    ...genericContexts[platform],
    sourceUrl: url
  };
};

