import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  buildPersistedRecipe,
  extractRecipeContextForImport,
  inferPlatformFromUrl,
  reconstructRecipe,
  type RawRecipeContext,
  type ReconstructionResult,
  type SourcePlatform
} from "../_shared/recipe-pipeline.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

const MAX_IMPORTS_PER_WINDOW = 8;
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;

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

const persistCompletedRecipe = async ({
  supabase,
  jobId,
  userId,
  sourceUrl,
  sourcePlatform,
  reconstruction
}: {
  supabase: ReturnType<typeof createClient>;
  jobId: string;
  userId: string;
  sourceUrl: string;
  sourcePlatform: SourcePlatform;
  reconstruction: ReconstructionResult;
}) => {
  const recipe = buildPersistedRecipe({
    jobId,
    sourceUrl,
    sourcePlatform,
    reconstruction
  });
  const { error: persistError } = await supabase.rpc("save_recipe_graph", {
    p_recipe_id: null,
    p_user_id: userId,
    p_import_job_id: jobId,
    p_status: recipe.status,
    p_title: recipe.title,
    p_description: recipe.description,
    p_hero_note: recipe.heroNote,
    p_image_label: recipe.imageLabel,
    p_thumbnail_url: recipe.thumbnailUrl,
    p_thumbnail_source: recipe.thumbnailSource,
    p_thumbnail_fallback_style: recipe.thumbnailFallbackStyle ?? null,
    p_servings: recipe.servings,
    p_prep_time_minutes: recipe.prepTimeMinutes,
    p_cook_time_minutes: recipe.cookTimeMinutes,
    p_total_time_minutes: recipe.totalTimeMinutes,
    p_confidence: recipe.confidence,
    p_confidence_score: recipe.confidenceScore,
    p_confidence_note: recipe.confidenceNote,
    p_inferred_fields: recipe.inferredFields,
    p_missing_fields: recipe.missingFields,
    p_raw_extraction: recipe.rawExtraction ?? null,
    p_source_creator: recipe.source.creator,
    p_source_url: recipe.source.url,
    p_source_platform: recipe.source.platform,
    p_tags: recipe.tags,
    p_ingredients: recipe.ingredients.map((ingredient) => ({
      name: ingredient.name,
      quantity: ingredient.quantity,
      optional: Boolean(ingredient.optional)
    })),
    p_steps: recipe.steps.map((step) => ({
      title: step.title,
      instruction: step.instruction,
      duration_minutes: step.durationMinutes ?? null
    }))
  });

  if (persistError) {
    throw persistError;
  }

  const { error: completionError } = await supabase
    .from("recipe_import_jobs")
    .update({
      status: "completed",
      progress: 1,
      stage_label: "Completed",
      stage_description: "Recipe is ready",
      normalized_recipe: recipe
    })
    .eq("id", jobId);

  if (completionError) {
    throw completionError;
  }

  return recipe;
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
  const sourcePlatform = source.source_platform as SourcePlatform;
  const sourcePayload = (source.raw_payload as Record<string, unknown> | null) ?? {};

  try {
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
      const context = await extractRecipeContextForImport({
        sourceUrl,
        sourcePlatform,
        sourcePayload
      });

      await supabase
        .from("import_sources")
        .update({
          creator_handle: context.creator ?? source.creator_handle ?? null,
          raw_payload: context
        })
        .eq("id", row.import_source_id);

      await supabase
        .from("recipe_import_jobs")
        .update({
          status: "extracting",
          progress: 0.28,
          stage_label: "Extracting content",
          stage_description: "Source metadata, creator context, and captions extracted",
          normalized_recipe: {
            stage: "extracting",
            rawExtraction: context,
            title: context.title ?? null,
            creator: context.creator ?? null,
            thumbnailUrl: context.thumbnailUrl ?? null
          }
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
      const context =
        ((row.normalized_recipe as { rawExtraction?: RawRecipeContext } | null)?.rawExtraction ??
          (await extractRecipeContextForImport({
            sourceUrl,
            sourcePlatform,
            sourcePayload
          }))) as RawRecipeContext;
      const reconstruction = await reconstructRecipe(context);
      const draftPayload = {
        stage: "identifying_ingredients",
        rawExtraction: context,
        title: reconstruction.title,
        description: reconstruction.description ?? null,
        ingredients: reconstruction.ingredients,
        thumbnailUrl: reconstruction.thumbnailUrl ?? null,
        sourceCreator: reconstruction.sourceCreator ?? null
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
      const context =
        ((row.normalized_recipe as { rawExtraction?: RawRecipeContext } | null)?.rawExtraction ??
          (await extractRecipeContextForImport({
            sourceUrl,
            sourcePlatform,
            sourcePayload
          }))) as RawRecipeContext;
      const reconstruction = await reconstructRecipe(context);
      const nextPayload = {
        stage: "building_steps",
        rawExtraction: context,
        title: reconstruction.title,
        ingredients: reconstruction.ingredients,
        steps: reconstruction.steps,
        inferredFields: reconstruction.inferredFields,
        missingFields: reconstruction.missingFields
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
      const context =
        ((row.normalized_recipe as { rawExtraction?: RawRecipeContext } | null)?.rawExtraction ??
          (await extractRecipeContextForImport({
            sourceUrl,
            sourcePlatform,
            sourcePayload
          }))) as RawRecipeContext;
      const reconstruction = await reconstructRecipe(context);
      const recipe = await persistCompletedRecipe({
        supabase,
        jobId: row.id,
        userId,
        sourceUrl,
        sourcePlatform,
        reconstruction
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
  } catch (error) {
    const message = error instanceof Error ? error.message : "Cooksy could not process this recipe import";
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
