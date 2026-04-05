-- Data Retention & GDPR Compliance
-- Automated cleanup jobs for privacy compliance

-- Retention configuration
create table if not exists public.retention_config (
  key text primary key,
  days integer not null,
  description text,
  updated_at timestamptz not null default timezone('utc', now())
);

-- Insert default retention policies
insert into public.retention_config (key, days, description) values
  ('analytics_events', 90, 'Anonymous analytics data'),
  ('import_job_logs', 30, 'Import job processing logs'),
  ('failed_imports', 90, 'Failed import job details'),
  ('user_activity_logs', 365, 'User activity audit logs'),
  ('deleted_recipes', 30, 'Soft-deleted recipes before permanent removal')
on conflict (key) do nothing;

-- Function to cleanup old analytics data
create or replace function public.cleanup_old_analytics()
returns table (deleted_count bigint)
language plpgsql
security definer
as $$
declare
  v_retention_days integer;
  v_deleted bigint;
begin
  select days into v_retention_days
  from public.retention_config
  where key = 'analytics_events';
  
  -- Note: This assumes you have an analytics_events table
  -- If using external analytics (PostHog), configure retention there
  
  -- For now, just return 0 since analytics are external
  return query select 0::bigint as deleted_count;
end;
$$;

-- Function to cleanup old import job logs
create or replace function public.cleanup_old_import_jobs()
returns table (deleted_count bigint)
language plpgsql
security definer
as $$
declare
  v_retention_days integer;
  v_cutoff timestamptz;
  v_deleted bigint;
begin
  select days into v_retention_days
  from public.retention_config
  where key = 'import_job_logs';
  
  v_cutoff := timezone('utc', now()) - (v_retention_days || ' days')::interval;
  
  -- Delete completed/failed jobs older than retention period
  -- Keep completed recipes, just clean up the job metadata
  with deleted as (
    delete from public.recipe_import_jobs
    where status in ('completed', 'failed')
      and updated_at < v_cutoff
      and exists (
        select 1 from public.recipes
        where recipes.import_job_id = recipe_import_jobs.id
        or recipes.created_at > v_cutoff
      )
    returning id
  )
  select count(*) into v_deleted from deleted;
  
  return query select v_deleted as deleted_count;
end;
$$;

-- Function to export user data (GDPR right to portability)
create or replace function public.export_user_data(p_user_id uuid)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'user_id', p_user_id,
    'exported_at', timezone('utc', now()),
    'recipes', coalesce(
      (select jsonb_agg(
        jsonb_build_object(
          'id', r.id,
          'title', r.title,
          'description', r.description,
          'created_at', r.created_at,
          'updated_at', r.updated_at,
          'ingredients', (
            select jsonb_agg(
              jsonb_build_object(
                'name', ri.name,
                'quantity', ri.quantity
              )
            )
            from public.recipe_ingredients ri
            where ri.recipe_id = r.id
          ),
          'steps', (
            select jsonb_agg(
              jsonb_build_object(
                'title', rs.title,
                'instruction', rs.instruction
              )
            )
            from public.recipe_steps rs
            where rs.recipe_id = r.id
          )
        )
      )
      from public.recipes r
      where r.user_id = p_user_id
    ), '[]'::jsonb),
    'books', coalesce(
      (select jsonb_agg(
        jsonb_build_object(
          'id', b.id,
          'name', b.name,
          'description', b.description,
          'created_at', b.created_at
        )
      )
      from public.recipe_books b
      where b.user_id = p_user_id
    ), '[]'::jsonb),
    'import_jobs', coalesce(
      (select jsonb_agg(
        jsonb_build_object(
          'id', j.id,
          'status', j.status,
          'created_at', j.created_at,
          'source_url', s.source_url
        )
      )
      from public.recipe_import_jobs j
      join public.import_sources s on s.id = j.import_source_id
      where j.user_id = p_user_id
    ), '[]'::jsonb)
  ) into v_result;
  
  -- Log the export for audit
  insert into public.user_data_exports (
    user_id,
    exported_at,
    data_hash
  ) values (
    p_user_id,
    timezone('utc', now()),
    md5(v_result::text)
  );
  
  return v_result;
end;
$$;

-- Table to track data exports (audit trail)
create table if not exists public.user_data_exports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exported_at timestamptz not null,
  data_hash text not null,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.user_data_exports enable row level security;

create policy "Users can view their own exports"
  on public.user_data_exports
  for select
  using (auth.uid() = user_id);

-- Function to delete user data (GDPR right to be forgotten)
create or replace function public.delete_user_account(p_user_id uuid)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_recipe_count integer;
  v_book_count integer;
  v_job_count integer;
begin
  -- Count what will be deleted
  select count(*) into v_recipe_count from public.recipes where user_id = p_user_id;
  select count(*) into v_book_count from public.recipe_books where user_id = p_user_id;
  select count(*) into v_job_count from public.recipe_import_jobs where user_id = p_user_id;
  
  -- Delete in proper order to respect foreign keys
  -- 1. Recipe book items (cascade from books)
  delete from public.recipe_book_items
  where book_id in (select id from public.recipe_books where user_id = p_user_id);
  
  -- 2. Recipe books
  delete from public.recipe_books where user_id = p_user_id;
  
  -- 3. Recipe ingredients and steps (cascade from recipes)
  delete from public.recipe_ingredients
  where recipe_id in (select id from public.recipes where user_id = p_user_id);
  
  delete from public.recipe_steps
  where recipe_id in (select id from public.recipes where user_id = p_user_id);
  
  -- 4. Content reports
  delete from public.content_reports
  where recipe_id in (select id from public.recipes where user_id = p_user_id)
     or reporter_user_id = p_user_id;
  
  -- 5. Recipes
  delete from public.recipes where user_id = p_user_id;
  
  -- 6. Import jobs and sources
  delete from public.recipe_import_jobs where user_id = p_user_id;
  delete from public.import_sources where user_id = p_user_id;
  
  -- 7. User data exports
  delete from public.user_data_exports where user_id = p_user_id;
  
  -- 8. Finally, delete the user (will cascade to auth.users via trigger)
  -- Note: This requires proper setup in auth schema
  
  return jsonb_build_object(
    'success', true,
    'deleted', jsonb_build_object(
      'recipes', v_recipe_count,
      'books', v_book_count,
      'jobs', v_job_count
    )
  );
end;
$$;

-- Grant access to authenticated users
grant execute on function public.export_user_data(uuid) to authenticated;
grant execute on function public.delete_user_account(uuid) to authenticated;

-- Note: Set up pg_cron extension for automated cleanup
-- This requires Supabase Pro or self-hosted
comment on function public.cleanup_old_import_jobs is 
  'Schedule this with pg_cron: SELECT cron.schedule(''cleanup-jobs'', ''0 3 * * *'', ''SELECT cleanup_old_import_jobs()'');';
