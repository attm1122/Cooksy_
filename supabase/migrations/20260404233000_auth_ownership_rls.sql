alter table public.import_sources
add column if not exists user_id uuid references auth.users(id);

alter table public.recipe_import_jobs
add column if not exists user_id uuid references auth.users(id);

alter table public.recipes
add column if not exists user_id uuid references auth.users(id);

alter table public.recipe_books
add column if not exists user_id uuid references auth.users(id);

alter table public.import_sources
drop constraint if exists import_sources_source_url_key;

create unique index if not exists import_sources_user_url_unique
on public.import_sources(user_id, source_url);

create index if not exists import_sources_user_id_idx on public.import_sources(user_id);
create index if not exists recipe_import_jobs_user_id_idx on public.recipe_import_jobs(user_id);
create index if not exists recipes_user_id_idx on public.recipes(user_id);
create index if not exists recipe_books_user_id_idx on public.recipe_books(user_id);

update public.recipe_import_jobs jobs
set user_id = sources.user_id
from public.import_sources sources
where jobs.import_source_id = sources.id
  and jobs.user_id is null;

update public.recipes recipes
set user_id = jobs.user_id
from public.recipe_import_jobs jobs
where recipes.import_job_id = jobs.id
  and recipes.user_id is null;

alter table public.import_sources enable row level security;
alter table public.recipe_import_jobs enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.recipe_steps enable row level security;
alter table public.recipe_books enable row level security;
alter table public.recipe_book_items enable row level security;

drop policy if exists "users can manage own import_sources" on public.import_sources;
create policy "users can manage own import_sources"
on public.import_sources
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can manage own import_jobs" on public.recipe_import_jobs;
create policy "users can manage own import_jobs"
on public.recipe_import_jobs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can manage own recipes" on public.recipes;
create policy "users can manage own recipes"
on public.recipes
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can manage own recipe_ingredients" on public.recipe_ingredients;
create policy "users can manage own recipe_ingredients"
on public.recipe_ingredients
for all
using (
  exists (
    select 1
    from public.recipes
    where public.recipes.id = public.recipe_ingredients.recipe_id
      and public.recipes.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.recipes
    where public.recipes.id = public.recipe_ingredients.recipe_id
      and public.recipes.user_id = auth.uid()
  )
);

drop policy if exists "users can manage own recipe_steps" on public.recipe_steps;
create policy "users can manage own recipe_steps"
on public.recipe_steps
for all
using (
  exists (
    select 1
    from public.recipes
    where public.recipes.id = public.recipe_steps.recipe_id
      and public.recipes.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.recipes
    where public.recipes.id = public.recipe_steps.recipe_id
      and public.recipes.user_id = auth.uid()
  )
);

drop policy if exists "users can manage own recipe_books" on public.recipe_books;
create policy "users can manage own recipe_books"
on public.recipe_books
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can manage own recipe_book_items" on public.recipe_book_items;
create policy "users can manage own recipe_book_items"
on public.recipe_book_items
for all
using (
  exists (
    select 1
    from public.recipe_books
    where public.recipe_books.id = public.recipe_book_items.book_id
      and public.recipe_books.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.recipe_books
    where public.recipe_books.id = public.recipe_book_items.book_id
      and public.recipe_books.user_id = auth.uid()
  )
  and exists (
    select 1
    from public.recipes
    where public.recipes.id = public.recipe_book_items.recipe_id
      and public.recipes.user_id = auth.uid()
  )
);
