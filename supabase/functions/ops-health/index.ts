import { createClient } from "npm:@supabase/supabase-js@2.49.8";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json"
    }
  });

Deno.serve(async (request) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !supabaseAnonKey) {
    return json(
      {
        ok: false,
        error: "Missing SUPABASE_URL or SUPABASE_ANON_KEY"
      },
      500
    );
  }

  const authHeader = request.headers.get("Authorization");

  if (!authHeader) {
    return json(
      {
        ok: false,
        error: "Missing Authorization header"
      },
      401
    );
  }

  const client = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authHeader
      }
    }
  });

  const {
    data: { user },
    error: authError
  } = await client.auth.getUser();

  if (authError || !user) {
    return json(
      {
        ok: false,
        error: authError?.message ?? "Unauthorized"
      },
      401
    );
  }

  const [recipesResult, booksResult, jobsResult] = await Promise.all([
    client.from("recipes").select("id", { count: "exact", head: true }),
    client.from("recipe_books").select("id", { count: "exact", head: true }),
    client.from("recipe_import_jobs").select("id", { count: "exact", head: true })
  ]);

  return json({
    ok: true,
    timestamp: new Date().toISOString(),
    userId: user.id,
    checks: {
      recipes: recipesResult.count ?? 0,
      books: booksResult.count ?? 0,
      importJobs: jobsResult.count ?? 0
    }
  });
});
