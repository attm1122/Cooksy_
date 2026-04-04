alter table public.recipes
add column if not exists status text not null default 'ready' check (status in ('processing', 'ready', 'failed')),
add column if not exists confidence_score integer not null default 0 check (confidence_score >= 0 and confidence_score <= 100),
add column if not exists inferred_fields text[] not null default '{}',
add column if not exists missing_fields text[] not null default '{}';

create unique index if not exists recipes_import_job_id_unique
on public.recipes(import_job_id)
where import_job_id is not null;
