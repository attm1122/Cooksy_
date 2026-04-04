alter table public.recipes
add column if not exists raw_extraction jsonb;
