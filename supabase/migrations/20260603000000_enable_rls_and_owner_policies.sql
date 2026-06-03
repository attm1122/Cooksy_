-- Cooksy Supabase security hardening for App Store resubmission.
-- Run this in Supabase SQL Editor or through the Supabase CLI against project
-- qirjjbmrgtailifhmakp before resubmitting the iOS build.

begin;

-- Enable RLS on every user table in the public schema so anon clients cannot
-- read, edit, or delete unrestricted data.
do $$
declare
    table_record record;
begin
    for table_record in
        select schemaname, tablename
        from pg_tables
        where schemaname = 'public'
          and tablename <> 'spatial_ref_sys'
    loop
        execute format('alter table %I.%I enable row level security', table_record.schemaname, table_record.tablename);
        execute format('alter table %I.%I force row level security', table_record.schemaname, table_record.tablename);
    end loop;
end $$;

-- Remove broad anonymous table access. Authenticated clients still need table
-- privileges, but RLS policies below decide which rows each user can access.
revoke all on table
    public.content_reports,
    public.import_sources,
    public.profiles,
    public.recipe_book_items,
    public.recipe_books,
    public.recipe_import_jobs,
    public.recipe_ingredients,
    public.recipe_steps,
    public.recipes,
    public.user_push_tokens
from anon;

grant select, insert, update, delete on table
    public.import_sources,
    public.recipe_book_items,
    public.recipe_books,
    public.recipe_import_jobs,
    public.recipe_ingredients,
    public.recipe_steps,
    public.recipes
to authenticated;

grant insert on table public.content_reports to authenticated;
grant insert, update on table public.profiles to authenticated;
grant insert, delete on table public.user_push_tokens to authenticated;

alter table public.user_push_tokens
    alter column user_id set default (auth.uid())::text;

alter table public.content_reports
    alter column user_id set default (auth.uid())::text;

-- User-owned root tables.
drop policy if exists "users can manage own recipes" on public.recipes;
create policy "users can manage own recipes"
on public.recipes for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can manage own recipe_books" on public.recipe_books;
create policy "users can manage own recipe_books"
on public.recipe_books for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can manage own import_sources" on public.import_sources;
create policy "users can manage own import_sources"
on public.import_sources for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can manage own import_jobs" on public.recipe_import_jobs;
create policy "users can manage own import_jobs"
on public.recipe_import_jobs for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Child tables inherit access from their parent recipe.
drop policy if exists "users can manage own recipe_ingredients" on public.recipe_ingredients;
create policy "users can manage own recipe_ingredients"
on public.recipe_ingredients for all
to authenticated
using (
    exists (
        select 1 from public.recipes
        where recipes.id = recipe_ingredients.recipe_id
          and recipes.user_id = auth.uid()
    )
)
with check (
    exists (
        select 1 from public.recipes
        where recipes.id = recipe_ingredients.recipe_id
          and recipes.user_id = auth.uid()
    )
);

drop policy if exists "users can manage own recipe_steps" on public.recipe_steps;
create policy "users can manage own recipe_steps"
on public.recipe_steps for all
to authenticated
using (
    exists (
        select 1 from public.recipes
        where recipes.id = recipe_steps.recipe_id
          and recipes.user_id = auth.uid()
    )
)
with check (
    exists (
        select 1 from public.recipes
        where recipes.id = recipe_steps.recipe_id
          and recipes.user_id = auth.uid()
    )
);

drop policy if exists "users can manage own recipe_book_items" on public.recipe_book_items;
create policy "users can manage own recipe_book_items"
on public.recipe_book_items for all
to authenticated
using (
    exists (
        select 1 from public.recipe_books
        where recipe_books.id = recipe_book_items.book_id
          and recipe_books.user_id = auth.uid()
    )
)
with check (
    exists (
        select 1 from public.recipe_books
        where recipe_books.id = recipe_book_items.book_id
          and recipe_books.user_id = auth.uid()
    )
    and exists (
        select 1 from public.recipes
        where recipes.id = recipe_book_items.recipe_id
          and recipes.user_id = auth.uid()
    )
);

-- Optional profile and operational tables, if present in the live project.
do $$
declare
    profile_owner_expression text := 'id = (auth.uid())::text';
begin
    if to_regclass('public.profiles') is not null then
        alter table public.profiles
            alter column id set default (auth.uid())::text;

        execute 'drop policy if exists "Users can read own profile" on public.profiles';
        execute format(
            'create policy "Users can read own profile" on public.profiles for select to authenticated using (%s)',
            profile_owner_expression
        );

        execute 'drop policy if exists "Users can manage own profile" on public.profiles';
        execute format(
            'create policy "Users can manage own profile" on public.profiles for all to authenticated using (%1$s) with check (%1$s)',
            profile_owner_expression
        );
    end if;

    if to_regclass('public.user_push_tokens') is not null then
        execute 'drop policy if exists "Users can manage own push tokens" on public.user_push_tokens';
        execute 'create policy "Users can manage own push tokens" on public.user_push_tokens for all to authenticated using (user_id = (auth.uid())::text) with check (user_id = (auth.uid())::text)';
    end if;

    if to_regclass('public.content_reports') is not null then
        execute 'drop policy if exists "Users can submit content reports" on public.content_reports';
        execute 'create policy "Users can submit content reports" on public.content_reports for insert to authenticated with check (user_id = (auth.uid())::text)';
    end if;
end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

revoke execute on function public.save_recipe_graph(
    uuid,
    uuid,
    uuid,
    text,
    text,
    text,
    text,
    text,
    text,
    text,
    text,
    integer,
    integer,
    integer,
    integer,
    text,
    integer,
    text,
    text[],
    text[],
    jsonb,
    text,
    text,
    text,
    text[],
    jsonb,
    jsonb
) from anon, authenticated;

commit;
