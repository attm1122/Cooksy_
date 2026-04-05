-- Content Reports Table
-- Stores user reports of inappropriate content for admin review

create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid references public.recipes(id) on delete cascade,
  reporter_user_id uuid references auth.users(id) on delete set null,
  reason text not null,
  details text,
  status text not null default 'pending' check (status in ('pending', 'reviewing', 'resolved', 'dismissed')),
  resolution_notes text,
  resolved_by uuid references auth.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- Index for efficient queries
comment on table public.content_reports is 'User reports of inappropriate recipe content';
create index if not exists content_reports_status_idx on public.content_reports(status);
create index if not exists content_reports_recipe_id_idx on public.content_reports(recipe_id);
create index if not exists content_reports_created_at_idx on public.content_reports(created_at desc);

-- RLS: Admins can manage all reports, users can only see their own
alter table public.content_reports enable row level security;

-- Policy: Users can create reports (anon or authenticated)
create policy "Anyone can create reports"
  on public.content_reports
  for insert
  with check (true);

-- Policy: Admins can view all reports
-- Note: Add your admin user IDs to the auth.users table or use a separate admin role
create policy "Admins can view all reports"
  on public.content_reports
  for select
  using (
    auth.uid() in (
      select user_id from public.user_roles where role = 'admin'
    )
  );

create policy "Admins can update reports"
  on public.content_reports
  for update
  using (
    auth.uid() in (
      select user_id from public.user_roles where role = 'admin'
    )
  );

-- User roles table for admin access
create table if not exists public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin', 'moderator')),
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id) on delete set null
);

alter table public.user_roles enable row level security;

-- Only admins can manage roles
create policy "Admins can manage roles"
  on public.user_roles
  for all
  using (
    auth.uid() in (
      select user_id from public.user_roles where role = 'admin'
    )
  );

-- Trigger to update updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists content_reports_set_updated_at on public.content_reports;
create trigger content_reports_set_updated_at
  before update on public.content_reports
  for each row
  execute function public.set_updated_at();

-- Function to get moderation stats for admin dashboard
create or replace function public.get_moderation_stats()
returns table (
  pending_reports bigint,
  flagged_content bigint,
  blocked_today bigint,
  total_reports bigint
)
language sql
security definer
as $$
  select
    (select count(*) from public.content_reports where status = 'pending') as pending_reports,
    (select count(*) from public.content_reports where status = 'reviewing') as flagged_content,
    (select count(*) from public.recipe_import_jobs where status = 'failed' and created_at > now() - interval '1 day') as blocked_today,
    (select count(*) from public.content_reports) as total_reports;
$$;

-- Function to report content (simplified for anonymous users)
create or replace function public.report_recipe_content(
  p_recipe_id uuid,
  p_reason text,
  p_details text default null,
  p_reporter_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_report_id uuid;
begin
  insert into public.content_reports (
    recipe_id,
    reporter_user_id,
    reason,
    details
  ) values (
    p_recipe_id,
    p_reporter_user_id,
    p_reason,
    p_details
  )
  returning id into v_report_id;
  
  return jsonb_build_object(
    'success', true,
    'report_id', v_report_id
  );
exception when others then
  return jsonb_build_object(
    'success', false,
    'error', sqlerrm
  );
end;
$$;
