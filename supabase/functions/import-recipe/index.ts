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

const buildMockRecipe = (sourceUrl: string, sourcePlatform: string) => ({
  title: "Cooksy Imported Chicken Orzo",
  description: "A starter imported recipe emitted by the first backend pipeline.",
  heroNote: "Generated from a social video URL and ready for later enrichment.",
  imageLabel: "Imported chicken orzo skillet",
  servings: 4,
  prepTimeMinutes: 15,
  cookTimeMinutes: 25,
  totalTimeMinutes: 40,
  confidence: "medium",
  confidenceNote: "Ingredient quantities and timings were inferred from source content.",
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

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

  const body = await request.json();
  const action = body.action;

  if (action === "create") {
    const sourceUrl = body.sourceUrl as string;
    const sourcePlatform = inferPlatformFromUrl(sourceUrl);

    const { data: importSource, error: importSourceError } = await supabase
      .from("import_sources")
      .upsert(
        {
          source_url: sourceUrl,
          source_platform: sourcePlatform
        },
        {
          onConflict: "source_url"
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
      .single();

    if (error) {
      return Response.json({ error: error.message }, { status: 404, headers: corsHeaders });
    }

    const source = Array.isArray(row.import_sources) ? row.import_sources[0] : row.import_sources;
    const normalizedRecipe =
      row.normalized_recipe ??
      (row.status === "completed"
        ? buildMockRecipe(source.source_url, source.source_platform)
        : undefined);

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
