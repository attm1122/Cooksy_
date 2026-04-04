import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

const inferPlatformFromUrl = (url: string) => {
  if (url.includes("tiktok")) {
    return "tiktok";
  }

  if (url.includes("instagram")) {
    return "instagram";
  }

  return "youtube";
};

const buildMockRecipe = (sourceUrl: string, sourcePlatform: string, importJobId: string) => ({
  status: "ready",
  importJobId,
  title: "Cooksy Imported Chicken Orzo",
  description: "A starter imported recipe emitted by the first backend pipeline.",
  heroNote: "Generated from a social video URL and ready for later enrichment.",
  imageLabel: "Imported chicken orzo skillet",
  thumbnailUrl: `https://picsum.photos/seed/${sourcePlatform}-imported-recipe/1280/960`,
  thumbnailSource: sourcePlatform,
  thumbnailFallbackStyle: "golden-sear",
  servings: 4,
  prepTimeMinutes: 15,
  cookTimeMinutes: 25,
  totalTimeMinutes: 40,
  confidence: "medium",
  confidenceScore: 74,
  confidenceNote: "Ingredient quantities and timings were inferred from source content.",
  inferredFields: ["Garlic quantity inferred", "Simmer timing estimated from visuals"],
  missingFields: ["Oven temperature not provided"],
  isSaved: true,
  source: {
    creator: "Imported Creator",
    url: sourceUrl,
    platform: sourcePlatform
  },
  ingredients: [
    { id: "ing-1", name: "Chicken thighs", quantity: "6 boneless" },
    { id: "ing-2", name: "Garlic cloves", quantity: "5 minced" },
    { id: "ing-3", name: "Orzo", quantity: "1 cup" }
  ],
  steps: [
    { id: "step-1", title: "Brown the chicken", instruction: "Sear the chicken until golden." },
    { id: "step-2", title: "Build the base", instruction: "Cook garlic, add orzo, and simmer with liquid." },
    { id: "step-3", title: "Finish and serve", instruction: "Reduce the sauce and serve warm." }
  ],
  tags: ["Imported", "Weeknight"]
});

const getJobState = (createdAt: string) => {
  const elapsedMs = Date.now() - new Date(createdAt).getTime();

  if (elapsedMs < 5_000) {
    return {
      status: "queued",
      progress: 0.08,
      stage_label: "Queued",
      stage_description: "Import request accepted and waiting to process"
    };
  }

  if (elapsedMs < 10_000) {
    return {
      status: "extracting",
      progress: 0.28,
      stage_label: "Extracting content",
      stage_description: "Pulling source metadata, captions, and creator context"
    };
  }

  if (elapsedMs < 15_000) {
    return {
      status: "identifying_ingredients",
      progress: 0.58,
      stage_label: "Identifying ingredients",
      stage_description: "Inferring ingredient list and estimated quantities"
    };
  }

  if (elapsedMs < 20_000) {
    return {
      status: "building_steps",
      progress: 0.86,
      stage_label: "Building steps",
      stage_description: "Structuring the cooking method and timings"
    };
  }

  return {
    status: "completed",
    progress: 1,
    stage_label: "Completed",
    stage_description: "Recipe is ready"
  };
};

const persistCompletedRecipe = async ({
  supabase,
  jobId,
  userId,
  sourceUrl,
  sourcePlatform
}: {
  supabase: ReturnType<typeof createClient>;
  jobId: string;
  userId: string;
  sourceUrl: string;
  sourcePlatform: string;
}) => {
  const mockRecipe = buildMockRecipe(sourceUrl, sourcePlatform, jobId);
  const { data: existingRecipe } = await supabase
    .from("recipes")
    .select("id")
    .eq("import_job_id", jobId)
    .eq("user_id", userId)
    .maybeSingle();

  let recipeId = existingRecipe?.id as string | undefined;

  if (!recipeId) {
    const { data: createdRecipe, error: recipeError } = await supabase
      .from("recipes")
      .insert({
        user_id: userId,
        import_job_id: jobId,
        status: mockRecipe.status,
        title: mockRecipe.title,
        description: mockRecipe.description,
        hero_note: mockRecipe.heroNote,
        image_label: mockRecipe.imageLabel,
        thumbnail_url: mockRecipe.thumbnailUrl,
        thumbnail_source: mockRecipe.thumbnailSource,
        thumbnail_fallback_style: mockRecipe.thumbnailFallbackStyle,
        servings: mockRecipe.servings,
        prep_time_minutes: mockRecipe.prepTimeMinutes,
        cook_time_minutes: mockRecipe.cookTimeMinutes,
        total_time_minutes: mockRecipe.totalTimeMinutes,
        confidence: mockRecipe.confidence,
        confidence_score: mockRecipe.confidenceScore,
        confidence_note: mockRecipe.confidenceNote,
        inferred_fields: mockRecipe.inferredFields,
        missing_fields: mockRecipe.missingFields,
        source_creator: mockRecipe.source.creator,
        source_url: mockRecipe.source.url,
        source_platform: mockRecipe.source.platform,
        tags: mockRecipe.tags
      })
      .select("id")
      .single();

    if (recipeError) {
      throw recipeError;
    }

    recipeId = createdRecipe.id;

    const ingredientRows = mockRecipe.ingredients.map((ingredient, index) => ({
      recipe_id: recipeId,
      position: index,
      name: ingredient.name,
      quantity: ingredient.quantity,
      optional: Boolean(ingredient.optional)
    }));

    const stepRows = mockRecipe.steps.map((step, index) => ({
      recipe_id: recipeId,
      position: index,
      title: step.title,
      instruction: step.instruction,
      duration_minutes: step.durationMinutes ?? null
    }));

    await supabase.from("recipe_ingredients").insert(ingredientRows);
    await supabase.from("recipe_steps").insert(stepRows);
  }

  await supabase
    .from("recipe_import_jobs")
    .update({
      status: "completed",
      progress: 1,
      stage_label: "Completed",
      stage_description: "Recipe is ready",
      normalized_recipe: mockRecipe
    })
    .eq("id", jobId);

  return mockRecipe;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);
  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: request.headers.get("Authorization") ?? ""
      }
    }
  });

  const {
    data: { user }
  } = await authClient.auth.getUser();

  if (!user) {
    return Response.json({ error: "Unauthorized" }, { status: 401, headers: corsHeaders });
  }

  const body = await request.json();
  const action = body.action;

  if (action === "create") {
    const sourceUrl = body.sourceUrl as string;
    const sourcePlatform = inferPlatformFromUrl(sourceUrl);

    const { data: importSource, error: importSourceError } = await supabase
      .from("import_sources")
      .upsert(
        {
          user_id: user.id,
          source_url: sourceUrl,
          source_platform: sourcePlatform
        },
        {
          onConflict: "user_id,source_url"
        }
      )
      .select("id")
      .single();

    if (importSourceError) {
      return Response.json({ error: importSourceError.message }, { status: 500, headers: corsHeaders });
    }

    const { data: job, error: jobError } = await supabase
      .from("recipe_import_jobs")
      .insert({
        user_id: user.id,
        import_source_id: importSource.id,
        status: "queued",
        progress: 0.08,
        stage_label: "Queued",
        stage_description: "Import request accepted and waiting to process"
      })
      .select("id, created_at, updated_at")
      .single();

    if (jobError) {
      return Response.json({ error: jobError.message }, { status: 500, headers: corsHeaders });
    }

    return Response.json(
      {
        job: {
          id: job.id,
          sourceUrl,
          sourcePlatform,
          status: "queued",
          progress: 0.08,
          detail: {
            label: "Queued",
            description: "Import request accepted and waiting to process"
          },
          createdAt: job.created_at,
          updatedAt: job.updated_at
        }
      },
      { headers: corsHeaders }
    );
  }

  if (action === "status") {
    const jobId = body.jobId as string;
    const { data: row, error } = await supabase
      .from("recipe_import_jobs")
      .select(
        `
          id,
          status,
          progress,
          stage_label,
          stage_description,
          error_message,
          normalized_recipe,
          created_at,
          updated_at,
          import_sources (
            source_url,
            source_platform
          )
        `
      )
      .eq("id", jobId)
      .eq("user_id", user.id)
      .single();

    if (error) {
      return Response.json({ error: error.message }, { status: 404, headers: corsHeaders });
    }

    const source = Array.isArray(row.import_sources) ? row.import_sources[0] : row.import_sources;
    const derivedState = row.status === "failed" ? null : getJobState(row.created_at);

    if (derivedState && derivedState.status !== row.status) {
      await supabase
        .from("recipe_import_jobs")
        .update(derivedState)
        .eq("id", jobId);
      row.status = derivedState.status;
      row.progress = derivedState.progress;
      row.stage_label = derivedState.stage_label;
      row.stage_description = derivedState.stage_description;
    }

    const normalizedRecipe =
      row.status === "completed"
        ? await persistCompletedRecipe({
            supabase,
            jobId,
            userId: user.id,
            sourceUrl: source.source_url,
            sourcePlatform: source.source_platform
          })
        : row.normalized_recipe ?? undefined;

    return Response.json(
      {
        job: {
          id: row.id,
          sourceUrl: source.source_url,
          sourcePlatform: source.source_platform,
          status: row.status,
          progress: Number(row.progress),
          detail: {
            label: row.stage_label,
            description: row.stage_description
          },
          errorMessage: row.error_message ?? undefined,
          recipe: normalizedRecipe,
          createdAt: row.created_at,
          updatedAt: row.updated_at
        }
      },
      { headers: corsHeaders }
    );
  }

  return Response.json({ error: "Unsupported action" }, { status: 400, headers: corsHeaders });
});
