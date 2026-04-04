import type { Recipe, RecipeBook } from "@/types/recipe";

export const mockRecipes: Recipe[] = [
  {
    id: "creamy-garlic-chicken",
    status: "ready",
    title: "Creamy Garlic Chicken",
    processingMessage: undefined,
    description: "Pan-seared chicken finished in a glossy garlic cream sauce with spinach and parmesan.",
    heroNote: "Comforting skillet dinner with weeknight speed and dinner-party polish.",
    imageLabel: "Creamy garlic chicken skillet",
    thumbnailUrl: "https://picsum.photos/seed/youtube-cooksy-garlic-chicken/1280/720",
    thumbnailSource: "youtube",
    thumbnailFallbackStyle: "golden-sear",
    servings: 4,
    prepTimeMinutes: 15,
    cookTimeMinutes: 25,
    totalTimeMinutes: 40,
    confidence: "high",
    confidenceScore: 92,
    confidenceNote: "Sauce thickness and garlic quantity were inferred from similar creator recipes.",
    inferredFields: ["Garlic quantity inferred", "Sauce thickness inferred from creator visuals"],
    missingFields: [],
    rawExtraction: {
      sourceUrl: "https://youtube.com/watch?v=cooksy-garlic-chicken",
      platform: "youtube",
      title: "Creamy Garlic Chicken",
      creator: "Mila's Kitchen",
      caption: "One pan creamy garlic chicken. Sear chicken thighs, add garlic and cream, then finish with spinach and parmesan.",
      transcript: "Start with six chicken thighs. Sear until golden, add five garlic cloves, one cup of cream, and finish with parmesan and spinach.",
      ocrText: ["6 chicken thighs", "5 garlic cloves", "1 cup cream"],
      comments: ["Used extra spinach and it worked.", "Needed the garlic amount and guessed 5 cloves."],
      metadata: {
        signalOrigins: ["oembed", "watch-page"]
      },
      thumbnailUrl: "https://picsum.photos/seed/youtube-cooksy-garlic-chicken/1280/720"
    },
    isSaved: true,
    source: {
      creator: "Mila's Kitchen",
      url: "https://youtube.com/watch?v=cooksy-garlic-chicken",
      platform: "youtube"
    },
    ingredients: [
      { id: "cgc-1", name: "Chicken thighs", quantity: "6 boneless" },
      { id: "cgc-2", name: "Garlic cloves", quantity: "5 minced" },
      { id: "cgc-3", name: "Heavy cream", quantity: "1 cup" },
      { id: "cgc-4", name: "Parmesan", quantity: "1/2 cup grated" },
      { id: "cgc-5", name: "Baby spinach", quantity: "2 handfuls" }
    ],
    steps: [
      { id: "cgc-s1", title: "Sear the chicken", instruction: "Season and sear chicken in a hot skillet until golden on both sides." },
      { id: "cgc-s2", title: "Build the sauce", instruction: "Lower the heat, cook garlic briefly, then stir in cream and parmesan until silky." },
      { id: "cgc-s3", title: "Finish", instruction: "Return chicken to the pan, simmer until cooked through, and fold in spinach before serving." }
    ],
    tags: ["Weeknight", "High Protein", "Comfort Food"]
  },
  {
    id: "crispy-hot-honey-salmon",
    status: "ready",
    title: "Crispy Hot Honey Salmon",
    processingMessage: undefined,
    description: "Roasted salmon with caramelized edges and a sticky hot honey glaze.",
    heroNote: "Fast, glossy, and strong on flavor without feeling heavy.",
    imageLabel: "Hot honey salmon fillet",
    thumbnailUrl: "https://picsum.photos/seed/tiktok-123456789/1280/960",
    thumbnailSource: "tiktok",
    thumbnailFallbackStyle: "paprika-glow",
    servings: 2,
    prepTimeMinutes: 10,
    cookTimeMinutes: 16,
    totalTimeMinutes: 26,
    confidence: "medium",
    confidenceScore: 73,
    confidenceNote: "Spice level and glaze reduction timing were estimated from the creator's narration.",
    inferredFields: ["Glaze reduction timing estimated", "Hot honey ratio inferred"],
    missingFields: ["Exact oven temperature not provided"],
    rawExtraction: {
      sourceUrl: "https://tiktok.com/@ninacooks/video/123456789",
      platform: "tiktok",
      title: "Crispy Hot Honey Salmon",
      creator: "Nina Cooks",
      caption: "Sticky salmon rice bowls for weeknights.",
      transcript: null,
      ocrText: ["2 salmon fillets", "3 tbsp honey", "rice bowl"],
      comments: ["I used garlic butter for the glaze.", "What oven temp did you use?"],
      metadata: {
        signalOrigins: ["open-graph", "json-ld"]
      },
      thumbnailUrl: "https://picsum.photos/seed/tiktok-123456789/1280/960"
    },
    isSaved: true,
    source: {
      creator: "Nina Cooks",
      url: "https://tiktok.com/@ninacooks/video/123456789",
      platform: "tiktok"
    },
    ingredients: [
      { id: "hhs-1", name: "Salmon fillets", quantity: "2" },
      { id: "hhs-2", name: "Honey", quantity: "3 tbsp" },
      { id: "hhs-3", name: "Chili crisp", quantity: "1 tbsp" },
      { id: "hhs-4", name: "Soy sauce", quantity: "1 tbsp" },
      { id: "hhs-5", name: "Lime", quantity: "1" }
    ],
    steps: [
      { id: "hhs-s1", title: "Season salmon", instruction: "Pat salmon dry, season with salt, and roast skin-side down until nearly cooked." },
      { id: "hhs-s2", title: "Glaze", instruction: "Mix honey, chili crisp, and soy sauce, then brush over salmon for the final roast." },
      { id: "hhs-s3", title: "Serve", instruction: "Finish with lime juice and spoon extra glaze over the top." }
    ],
    tags: ["High Protein", "Dinner", "Seafood"]
  },
  {
    id: "one-pan-tuscan-pasta",
    status: "ready",
    title: "One Pan Tuscan Pasta",
    processingMessage: undefined,
    description: "Creamy sun-dried tomato pasta with spinach, garlic, and a soft chilli finish.",
    heroNote: "Minimal cleanup with a rich, glossy sauce that still feels relaxed.",
    imageLabel: "Tuscan pasta bowl",
    thumbnailUrl: "https://picsum.photos/seed/instagram-CooksyTuscanPasta/1280/960",
    thumbnailSource: "instagram",
    thumbnailFallbackStyle: "toast-cream",
    servings: 4,
    prepTimeMinutes: 12,
    cookTimeMinutes: 22,
    totalTimeMinutes: 34,
    confidence: "high",
    confidenceScore: 88,
    confidenceNote: "Liquid ratio was confidently inferred from the visible pan consistency and cooking time.",
    inferredFields: ["Liquid ratio inferred from pan consistency"],
    missingFields: ["Final chilli amount not shown"],
    rawExtraction: {
      sourceUrl: "https://instagram.com/reel/CooksyTuscanPasta",
      platform: "instagram",
      title: "One Pan Tuscan Pasta",
      creator: "Luca at Home",
      caption: "Creamy tuscan pasta with spinach and parmesan.",
      transcript: null,
      ocrText: ["12 oz rigatoni", "3 cups stock", "3/4 cup cream"],
      comments: ["Need the parmesan amount.", "Looks like 4 servings."],
      metadata: {
        signalOrigins: ["open-graph", "json-ld"]
      },
      thumbnailUrl: "https://picsum.photos/seed/instagram-CooksyTuscanPasta/1280/960"
    },
    isSaved: false,
    source: {
      creator: "Luca at Home",
      url: "https://instagram.com/reel/CooksyTuscanPasta",
      platform: "instagram"
    },
    ingredients: [
      { id: "otp-1", name: "Rigatoni", quantity: "12 oz" },
      { id: "otp-2", name: "Sun-dried tomatoes", quantity: "1/2 cup sliced" },
      { id: "otp-3", name: "Garlic", quantity: "4 cloves" },
      { id: "otp-4", name: "Vegetable stock", quantity: "3 cups" },
      { id: "otp-5", name: "Cream", quantity: "3/4 cup" }
    ],
    steps: [
      { id: "otp-s1", title: "Start the base", instruction: "Cook garlic and sun-dried tomatoes in a wide pan until fragrant." },
      { id: "otp-s2", title: "Cook pasta", instruction: "Add stock, cream, and pasta, then simmer until the pasta is tender and glossy." },
      { id: "otp-s3", title: "Finish", instruction: "Fold in spinach and parmesan, then let the sauce settle before serving." }
    ],
    tags: ["Weeknight", "Vegetarian", "Comfort Food"]
  }
];

export const mockBooks: RecipeBook[] = [
  {
    id: "weeknight",
    name: "Weeknight",
    description: "Reliable dinners that feel easy after a long day.",
    coverTone: "yellow",
    recipeIds: ["creamy-garlic-chicken", "one-pan-tuscan-pasta"]
  },
  {
    id: "high-protein",
    name: "High Protein",
    description: "Recipes with strong protein and simple prep.",
    coverTone: "cream",
    recipeIds: ["creamy-garlic-chicken", "crispy-hot-honey-salmon"]
  },
  {
    id: "comfort-food",
    name: "Comfort Food",
    description: "Rich, cozy recipes worth keeping on repeat.",
    coverTone: "ink",
    recipeIds: ["creamy-garlic-chicken", "one-pan-tuscan-pasta"]
  },
  {
    id: "date-night",
    name: "Date Night",
    description: "A little extra polish without extra stress.",
    coverTone: "yellow",
    recipeIds: ["crispy-hot-honey-salmon"]
  }
];
