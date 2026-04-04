import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

const MAX_IMPORTS_PER_WINDOW = 8;
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;

const inferPlatformFromUrl = (value: string) => {
  try {
    const url = new URL(value);
    const host = url.hostname.toLowerCase().replace(/^www\./, "");
    const path = url.pathname.toLowerCase();

    if (host === "youtu.be" && path.length > 1) {
      return "youtube";
    }

    if (["youtube.com", "m.youtube.com"].includes(host)) {
      if ((path.startsWith("/watch") && url.searchParams.get("v")) || path.startsWith("/shorts/") || path.startsWith("/live/")) {
        return "youtube";
      }
    }

    if (["tiktok.com", "m.tiktok.com", "vm.tiktok.com"].includes(host) && (path.includes("/video/") || path.startsWith("/t/"))) {
      return "tiktok";
    }

    if (host === "instagram.com" && (path.startsWith("/reel/") || path.startsWith("/p/") || path.startsWith("/tv/"))) {
      return "instagram";
    }
  } catch {
    return null;
  }

  return null;
};

const buildJobResponse = ({
  id,
  sourceUrl,
  sourcePlatform,
  status,
  progress,
  stageLabel,
  stageDescription,
  createdAt,
  updatedAt
}: {
  id: string;
  sourceUrl: string;
  sourcePlatform: string;
  status: string;
  progress: number;
  stageLabel: string;
  stageDescription: string;
  createdAt: string;
  updatedAt: string;
}) => ({
  job: {
    id,
    sourceUrl,
    sourcePlatform,
    status,
    progress,
    detail: {
      label: stageLabel,
      description: stageDescription
    },
    createdAt,
    updatedAt
  }
});

const buildRecipeFromSource = ({
  sourceUrl,
  sourcePlatform,
  importJobId,
  creatorHandle,
  titleHint
}: {
  sourceUrl: string;
  sourcePlatform: string;
  importJobId: string;
  creatorHandle: string;
  titleHint: string;
}) => ({
  status: "ready",
  importJobId,
  title: titleHint,
  description: "A staged imported recipe emitted by the backend pipeline and ready for later enrichment.",
  heroNote: "Generated from a social video URL with extracted source cues, structured ingredients, and drafted cooking steps.",
  imageLabel: `${titleHint} cover`,
  thumbnailUrl: `https://picsum.photos/seed/${sourcePlatform}-${titleHint.toLowerCase().replace(/\s+/g, "-")}/1280/960`,
  thumbnailSource: sourcePlatform,
  thumbnailFallbackStyle: "golden-sear",
  servings: 4,
  prepTimeMinutes: 15,
  cookTimeMinutes: 25,
  totalTimeMinutes: 40,
  confidence: "medium",
  confidenceScore: 76,
  confidenceNote: "Ingredient quantities and timings were inferred from extracted creator cues and source visuals.",
  inferredFields: ["Garlic quantity inferred", "Simmer timing estimated from source pacing"],
  missingFields: ["Exact oven temperature not provided"],
  isSaved: true,
  source: {
    creator: creatorHandle,
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

const deriveSourceMetadata = (sourceUrl: string, sourcePlatform: string) => {
  const sourceId = sourceUrl.split("/").filter(Boolean).pop()?.split("?")[0] ?? "imported";
  const creatorHandle =
    sourcePlatform === "youtube"
      ? "Cooksy Creator"
      : sourcePlatform === "tiktok"
        ? "@cooksycreator"
        : "cooksy.kitchen";
  const titleHint =
    sourcePlatform === "youtube"
      ? "Creamy Garlic Chicken Orzo"
      : sourcePlatform === "tiktok"
        ? "Hot Honey Salmon Rice Bowl"
        : "One Pan Tuscan Pasta";

  return {
    sourceId,
    creatorHandle,
    titleHint,
    caption: `Imported from ${sourcePlatform} source ${sourceId}`,
    extractedAt: new Date().toISOString()
  };
};

const persistCompletedRecipe = async ({
  supabase,
  jobId,
  userId,
  sourceUrl,
  sourcePlatform,
  sourcePayload
}: {
  supabase: ReturnType<typeof createClient>;
  jobId: string;
  userId: string;
  sourceUrl: string;
  sourcePlatform: string;
  sourcePayload?: Record<string, unknown>;
}) => {
  const creatorHandle =
    typeof sourcePayload?.creatorHandle === "string" ? sourcePayload.creatorHandle : "Imported Creator";
  const titleHint = typeof sourcePayload?.titleHint === "string" ? sourcePayload.titleHint : "Cooksy Imported Recipe";
  const mockRecipe = buildRecipeFromSource({
    sourceUrl,
    sourcePlatform,
    importJobId: jobId,
    creatorHandle,
    titleHint
  });
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

const failImportJob = async ({
  supabase,
  jobId,
  message
}: {
  supabase: ReturnType<typeof createClient>;
  jobId: string;
  message: string;
}) => {
  await supabase
    .from("recipe_import_jobs")
    .update({
      status: "failed",
      progress: 1,
      stage_label: "Import failed",
      stage_description: message,
      error_message: message
    })
    .eq("id", jobId);
};

const advancePipeline = async ({
  supabase,
  row,
  source,
  userId
}: {
  supabase: ReturnType<typeof createClient>;
  row: any;
  source: any;
  userId: string;
}) => {
  const sourceUrl = source.source_url as string;
  const sourcePlatform = source.source_platform as string;
  const sourcePayload = (source.raw_payload as Record<string, unknown> | null) ?? {};

  if (sourceUrl.includes("/story/") || sourceUrl.includes("private") || sourceUrl.includes("unavailable")) {
    const message = "This source looks unavailable or too limited to reconstruct. Try a public video or reel link.";
    await failImportJob({
      supabase,
      jobId: row.id,
      message
    });

    return {
      ...row,
      status: "failed",
      progress: 1,
      stage_label: "Import failed",
      stage_description: message,
      error_message: message,
      normalized_recipe: row.normalized_recipe ?? null
    };
  }

  if (row.status === "queued") {
    const metadata = deriveSourceMetadata(sourceUrl, sourcePlatform);

    await supabase
      .from("import_sources")
      .update({
        creator_handle: metadata.creatorHandle,
        raw_payload: {
          ...sourcePayload,
          metadata
        }
      })
      .eq("id", row.import_source_id);

    await supabase
      .from("recipe_import_jobs")
      .update({
        status: "extracting",
        progress: 0.28,
        stage_label: "Extracting content",
        stage_description: "Source metadata, creator context, and captions extracted"
      })
      .eq("id", row.id);

    return {
      ...row,
      status: "extracting",
      progress: 0.28,
      stage_label: "Extracting content",
      stage_description: "Source metadata, creator context, and captions extracted"
    };
  }

  if (row.status === "extracting") {
    const draftPayload = {
      ...sourcePayload,
      draftIngredients: [
        "Chicken thighs",
        "Garlic cloves",
        "Orzo"
      ]
    };

    await supabase
      .from("recipe_import_jobs")
      .update({
        status: "identifying_ingredients",
        progress: 0.58,
        stage_label: "Identifying ingredients",
        stage_description: "Drafting ingredient list and estimated quantities",
        normalized_recipe: draftPayload
      })
      .eq("id", row.id);

    return {
      ...row,
      status: "identifying_ingredients",
      progress: 0.58,
      stage_label: "Identifying ingredients",
      stage_description: "Drafting ingredient list and estimated quantities",
      normalized_recipe: draftPayload
    };
  }

  if (row.status === "identifying_ingredients") {
    const nextPayload = {
      ...(row.normalized_recipe ?? {}),
      draftSteps: [
        "Brown the protein",
        "Build the sauce or base",
        "Finish and serve"
      ]
    };

    await supabase
      .from("recipe_import_jobs")
      .update({
        status: "building_steps",
        progress: 0.86,
        stage_label: "Building steps",
        stage_description: "Structuring the cooking method and timings",
        normalized_recipe: nextPayload
      })
      .eq("id", row.id);

    return {
      ...row,
      status: "building_steps",
      progress: 0.86,
      stage_label: "Building steps",
      stage_description: "Structuring the cooking method and timings",
      normalized_recipe: nextPayload
    };
  }

  if (row.status === "building_steps") {
    const recipe = await persistCompletedRecipe({
      supabase,
      jobId: row.id,
      userId,
      sourceUrl,
      sourcePlatform,
      sourcePayload: {
        ...sourcePayload,
        ...(row.normalized_recipe ?? {})
      }
    });

    return {
      ...row,
      status: "completed",
      progress: 1,
      stage_label: "Completed",
      stage_description: "Recipe is ready",
      normalized_recipe: recipe
    };
  }

  return row;
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

    if (!sourcePlatform) {
      return Response.json(
        {
          error: "Cooksy currently supports YouTube, TikTok, and Instagram recipe links"
        },
        { status: 400, headers: corsHeaders }
      );
    }

    const rateLimitWindowStart = new Date(Date.now() - RATE_LIMIT_WINDOW_MS).toISOString();
    const { count: recentImportCount, error: rateLimitError } = await supabase
      .from("recipe_import_jobs")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .gte("created_at", rateLimitWindowStart);

    if (rateLimitError) {
      return Response.json({ error: rateLimitError.message }, { status: 500, headers: corsHeaders });
    }

    if ((recentImportCount ?? 0) >= MAX_IMPORTS_PER_WINDOW) {
      return Response.json(
        {
          error: "You have reached the current import limit. Please wait a few minutes before trying again."
        },
        { status: 429, headers: corsHeaders }
      );
    }

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

    const { data: existingJob, error: existingJobError } = await supabase
      .from("recipe_import_jobs")
      .select("id, status, progress, stage_label, stage_description, created_at, updated_at")
      .eq("user_id", user.id)
      .eq("import_source_id", importSource.id)
      .in("status", ["queued", "extracting", "identifying_ingredients", "building_steps"])
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existingJobError) {
      return Response.json({ error: existingJobError.message }, { status: 500, headers: corsHeaders });
    }

    if (existingJob) {
      return Response.json(
        buildJobResponse({
          id: existingJob.id,
          sourceUrl,
          sourcePlatform,
          status: existingJob.status,
          progress: Number(existingJob.progress),
          stageLabel: existingJob.stage_label,
          stageDescription: existingJob.stage_description,
          createdAt: existingJob.created_at,
          updatedAt: existingJob.updated_at
        }),
        { headers: corsHeaders }
      );
    }

    const { data: completedJob, error: completedJobError } = await supabase
      .from("recipe_import_jobs")
      .select("id, status, progress, stage_label, stage_description, created_at, updated_at")
      .eq("user_id", user.id)
      .eq("import_source_id", importSource.id)
      .eq("status", "completed")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (completedJobError) {
      return Response.json({ error: completedJobError.message }, { status: 500, headers: corsHeaders });
    }

    if (completedJob) {
      return Response.json(
        buildJobResponse({
          id: completedJob.id,
          sourceUrl,
          sourcePlatform,
          status: completedJob.status,
          progress: Number(completedJob.progress),
          stageLabel: completedJob.stage_label,
          stageDescription: completedJob.stage_description,
          createdAt: completedJob.created_at,
          updatedAt: completedJob.updated_at
        }),
        { headers: corsHeaders }
      );
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
      buildJobResponse({
        id: job.id,
        sourceUrl,
        sourcePlatform,
        status: "queued",
        progress: 0.08,
        stageLabel: "Queued",
        stageDescription: "Import request accepted and waiting to process",
        createdAt: job.created_at,
        updatedAt: job.updated_at
      }),
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
          import_source_id,
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
            source_platform,
            raw_payload
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
    const nextRow =
      row.status === "completed" || row.status === "failed"
        ? row
        : await advancePipeline({
            supabase,
            row,
            source,
            userId: user.id
          });

    const normalizedRecipe =
      nextRow.status === "completed"
        ? nextRow.normalized_recipe ?? undefined
        : undefined;

    return Response.json(
      {
        job: {
          id: nextRow.id,
          sourceUrl: source.source_url,
          sourcePlatform: source.source_platform,
          status: nextRow.status,
          progress: Number(nextRow.progress),
          detail: {
            label: nextRow.stage_label,
            description: nextRow.stage_description
          },
          errorMessage: nextRow.error_message ?? undefined,
          recipe: normalizedRecipe,
          createdAt: nextRow.created_at,
          updatedAt: nextRow.updated_at
        }
      },
      { headers: corsHeaders }
    );
  }

  return Response.json({ error: "Unsupported action" }, { status: 400, headers: corsHeaders });
});
