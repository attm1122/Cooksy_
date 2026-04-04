import { mockRecipes } from "@/mocks/recipes";

type RecipeServiceModule = typeof import("@/services/recipe-service");

type LoadModuleOptions = {
  recipeImportMode?: "mock" | "remote" | "auto";
  hasSupabaseConfig?: boolean;
  supabase?: unknown;
};

const loadRecipeService = ({
  recipeImportMode = "auto",
  hasSupabaseConfig = true,
  supabase = null
}: LoadModuleOptions = {}): RecipeServiceModule => {
  jest.resetModules();

  jest.doMock("@/lib/env", () => ({
    appEnv: {
      recipeImportMode,
      supabaseUrl: hasSupabaseConfig ? "https://cooksy.supabase.co" : undefined,
      supabaseAnonKey: hasSupabaseConfig ? "anon-key" : undefined
    },
    hasSupabaseConfig
  }));

  jest.doMock("@/lib/supabase", () => ({
    supabase
  }));

  jest.doMock("@/lib/analytics", () => ({
    trackEvent: jest.fn()
  }));

  jest.doMock("@/lib/monitoring", () => ({
    captureError: jest.fn()
  }));

  let recipeService: RecipeServiceModule | undefined;

  jest.isolateModules(() => {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    recipeService = require("@/services/recipe-service") as RecipeServiceModule;
  });

  return recipeService!;
};

describe("recipe-service production integrity", () => {
  afterEach(() => {
    jest.resetModules();
    jest.clearAllMocks();
    jest.unmock("@/lib/env");
    jest.unmock("@/lib/supabase");
    jest.unmock("@/lib/analytics");
    jest.unmock("@/lib/monitoring");
  });

  it("throws instead of falling back to mock recipes when remote hydration fails", async () => {
    const limit = jest.fn(async () => ({ data: null, error: new Error("recipes unavailable") }));
    const order = jest.fn(() => ({ limit }));
    const select = jest.fn(() => ({ order }));
    const from = jest.fn(() => ({ select }));

    const recipeService = loadRecipeService({
      recipeImportMode: "auto",
      hasSupabaseConfig: true,
      supabase: { from }
    });

    await expect(recipeService.fetchRecentRecipes()).rejects.toThrow("recipes unavailable");
  });

  it("throws when transactional recipe persistence fails", async () => {
    const rpc = jest.fn(async () => ({ error: new Error("save graph failed") }));

    const recipeService = loadRecipeService({
      recipeImportMode: "auto",
      hasSupabaseConfig: true,
      supabase: { rpc }
    });

    await expect(recipeService.updateRecipeInBackend(mockRecipes[0]!)).rejects.toThrow("save graph failed");
    expect(rpc).toHaveBeenCalledWith(
      "save_recipe_graph",
      expect.objectContaining({
        p_recipe_id: mockRecipes[0]!.id,
        p_title: mockRecipes[0]!.title
      })
    );
  });

  it("throws instead of fabricating a local-only book when backend creation fails", async () => {
    const getUser = jest.fn(async () => ({
      data: {
        user: { id: "user-123" }
      },
      error: null
    }));
    const single = jest.fn(async () => ({ data: null, error: new Error("insert denied") }));
    const select = jest.fn(() => ({ single }));
    const insert = jest.fn(() => ({ select }));
    const from = jest.fn(() => ({ insert }));

    const recipeService = loadRecipeService({
      recipeImportMode: "auto",
      hasSupabaseConfig: true,
      supabase: { from, auth: { getUser } }
    });

    await expect(
      recipeService.createRecipeBookInBackend({
        name: "Weeknight",
        description: "Reliable dinners",
        coverTone: "yellow"
      })
    ).rejects.toThrow("insert denied");
  });

  it("includes the authenticated user when creating recipe books remotely", async () => {
    const getUser = jest.fn(async () => ({
      data: {
        user: { id: "user-123" }
      },
      error: null
    }));
    const single = jest.fn(async () => ({
      data: {
        id: "book-1",
        name: "Weeknight",
        description: "Reliable dinners",
        cover_tone: "yellow"
      },
      error: null
    }));
    const select = jest.fn(() => ({ single }));
    const insert = jest.fn(() => ({ select }));
    const from = jest.fn(() => ({ insert }));

    const recipeService = loadRecipeService({
      recipeImportMode: "auto",
      hasSupabaseConfig: true,
      supabase: { from, auth: { getUser } }
    });

    await recipeService.createRecipeBookInBackend({
      name: "Weeknight",
      description: "Reliable dinners",
      coverTone: "yellow"
    });

    expect(insert).toHaveBeenCalledWith(
      expect.objectContaining({
        user_id: "user-123",
        name: "Weeknight"
      })
    );
  });

  it("hydrates a single recipe from Supabase when available", async () => {
    const maybeSingle = jest.fn(async () => ({
      data: {
        id: "recipe-1",
        status: "ready",
        import_job_id: null,
        title: "Remote Recipe",
        description: "Fetched from Supabase",
        hero_note: "Saved remotely",
        image_label: "Recipe cover",
        thumbnail_url: null,
        thumbnail_source: "generated",
        thumbnail_fallback_style: null,
        servings: 2,
        prep_time_minutes: 10,
        cook_time_minutes: 20,
        total_time_minutes: 30,
        confidence: "medium",
        confidence_score: 70,
        confidence_note: "Looks solid",
        inferred_fields: [],
        missing_fields: [],
        raw_extraction: null,
        source_creator: "Cooksy",
        source_url: "https://example.com/recipe",
        source_platform: "youtube",
        tags: [],
        recipe_ingredients: [],
        recipe_steps: []
      },
      error: null
    }));
    const eq = jest.fn(() => ({ maybeSingle }));
    const select = jest.fn(() => ({ eq }));
    const from = jest.fn(() => ({ select }));

    const recipeService = loadRecipeService({
      recipeImportMode: "auto",
      hasSupabaseConfig: true,
      supabase: { from }
    });

    const recipe = await recipeService.fetchRecipeById("recipe-1");

    expect(recipe?.id).toBe("recipe-1");
    expect(eq).toHaveBeenCalledWith("id", "recipe-1");
  });

  it("keeps mock fallbacks only in explicit mock mode", async () => {
    const recipeService = loadRecipeService({
      recipeImportMode: "mock",
      hasSupabaseConfig: false,
      supabase: null
    });

    await expect(recipeService.fetchRecentRecipes()).resolves.toHaveLength(mockRecipes.length);
  });
});
