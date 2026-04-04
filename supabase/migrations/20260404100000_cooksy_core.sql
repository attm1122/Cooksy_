create extension if not exists "pgcrypto";

create table if not exists public.import_sources (
  id uuid primary key default gen_random_uuid(),
  source_url text not null unique,
  source_platform text not null check (source_platform in ('youtube', 'tiktok', 'instagram')),
  creator_handle text,
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.recipe_import_jobs (
  id uuid primary key default gen_random_uuid(),
  import_source_id uuid not null references public.import_sources(id) on delete cascade,
  status text not null check (status in ('queued', 'extracting', 'identifying_ingredients', 'building_steps', 'completed', 'failed')),
  progress numeric(4, 3) not null default 0,
  stage_label text not null,
  stage_description text not null,
  error_message text,
  normalized_recipe jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists recipe_import_jobs_import_source_id_idx on public.recipe_import_jobs(import_source_id);
create index if not exists recipe_import_jobs_status_idx on public.recipe_import_jobs(status);

create table if not exists public.recipes (
  id uuid primary key default gen_random_uuid(),
  import_job_id uuid references public.recipe_import_jobs(id) on delete set null,
  title text not null,
  description text not null default '',
  hero_note text not null default '',
  image_label text,
  thumbnail_url text,
  thumbnail_source text not null default 'generated' check (thumbnail_source in ('youtube', 'tiktok', 'instagram', 'generated')),
  thumbnail_fallback_style text,
  servings integer not null default 2,
  prep_time_minutes integer not null default 0,
  cook_time_minutes integer not null default 0,
  total_time_minutes integer not null default 0,
  confidence text not null check (confidence in ('high', 'medium', 'low')),
  confidence_note text not null default '',
  source_creator text not null default '',
  source_url text not null,
  source_platform text not null check (source_platform in ('youtube', 'tiktok', 'instagram')),
  tags text[] not null default '{}',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  position integer not null,
  name text not null,
  quantity text not null,
  optional boolean not null default false
);

create index if not exists recipe_ingredients_recipe_id_idx on public.recipe_ingredients(recipe_id, position);

create table if not exists public.recipe_steps (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  position integer not null,
  title text not null,
  instruction text not null,
  duration_minutes integer
);

create index if not exists recipe_steps_recipe_id_idx on public.recipe_steps(recipe_id, position);

create table if not exists public.recipe_books (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  cover_tone text not null check (cover_tone in ('yellow', 'cream', 'ink')),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.recipe_book_items (
  book_id uuid not null references public.recipe_books(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (book_id, recipe_id)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists recipe_import_jobs_set_updated_at on public.recipe_import_jobs;
create trigger recipe_import_jobs_set_updated_at
before update on public.recipe_import_jobs
for each row
execute function public.set_updated_at();

drop trigger if exists recipes_set_updated_at on public.recipes;
create trigger recipes_set_updated_at
before update on public.recipes
for each row
execute function public.set_updated_at();
