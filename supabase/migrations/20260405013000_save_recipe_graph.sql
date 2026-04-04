create or replace function public.save_recipe_graph(
  p_recipe_id uuid default null,
  p_user_id uuid default null,
  p_import_job_id uuid default null,
  p_status text default 'ready',
  p_title text default '',
  p_description text default '',
  p_hero_note text default '',
  p_image_label text default null,
  p_thumbnail_url text default null,
  p_thumbnail_source text default 'generated',
  p_thumbnail_fallback_style text default null,
  p_servings integer default 2,
  p_prep_time_minutes integer default 0,
  p_cook_time_minutes integer default 0,
  p_total_time_minutes integer default 0,
  p_confidence text default 'medium',
  p_confidence_score integer default 0,
  p_confidence_note text default '',
  p_inferred_fields text[] default '{}',
  p_missing_fields text[] default '{}',
  p_raw_extraction jsonb default null,
  p_source_creator text default '',
  p_source_url text default '',
  p_source_platform text default 'youtube',
  p_tags text[] default '{}',
  p_ingredients jsonb default '[]'::jsonb,
  p_steps jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request_uid uuid := auth.uid();
  v_request_role text := auth.role();
  v_actor uuid := coalesce(p_user_id, v_request_uid);
  v_recipe_id uuid := p_recipe_id;
begin
  if v_request_role is distinct from 'service_role'
     and p_user_id is not null
     and p_user_id <> v_request_uid then
    raise exception 'Cannot write recipe graph for another user';
  end if;

  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if v_recipe_id is null and p_import_job_id is not null then
    select id
    into v_recipe_id
    from public.recipes
    where import_job_id = p_import_job_id
      and user_id = v_actor
    limit 1;
  end if;

  if v_recipe_id is null then
    insert into public.recipes (
      user_id,
      import_job_id,
      status,
      title,
      description,
      hero_note,
      image_label,
      thumbnail_url,
      thumbnail_source,
      thumbnail_fallback_style,
      servings,
      prep_time_minutes,
      cook_time_minutes,
      total_time_minutes,
      confidence,
      confidence_score,
      confidence_note,
      inferred_fields,
      missing_fields,
      raw_extraction,
      source_creator,
      source_url,
      source_platform,
      tags
    ) values (
      v_actor,
      p_import_job_id,
      p_status,
      p_title,
      p_description,
      p_hero_note,
      p_image_label,
      p_thumbnail_url,
      p_thumbnail_source,
      p_thumbnail_fallback_style,
      p_servings,
      p_prep_time_minutes,
      p_cook_time_minutes,
      p_total_time_minutes,
      p_confidence,
      p_confidence_score,
      p_confidence_note,
      p_inferred_fields,
      p_missing_fields,
      p_raw_extraction,
      p_source_creator,
      p_source_url,
      p_source_platform,
      p_tags
    )
    returning id into v_recipe_id;
  else
    update public.recipes
    set
      import_job_id = coalesce(p_import_job_id, import_job_id),
      status = p_status,
      title = p_title,
      description = p_description,
      hero_note = p_hero_note,
      image_label = p_image_label,
      thumbnail_url = p_thumbnail_url,
      thumbnail_source = p_thumbnail_source,
      thumbnail_fallback_style = p_thumbnail_fallback_style,
      servings = p_servings,
      prep_time_minutes = p_prep_time_minutes,
      cook_time_minutes = p_cook_time_minutes,
      total_time_minutes = p_total_time_minutes,
      confidence = p_confidence,
      confidence_score = p_confidence_score,
      confidence_note = p_confidence_note,
      inferred_fields = p_inferred_fields,
      missing_fields = p_missing_fields,
      raw_extraction = p_raw_extraction,
      source_creator = p_source_creator,
      source_url = p_source_url,
      source_platform = p_source_platform,
      tags = p_tags,
      updated_at = timezone('utc', now())
    where id = v_recipe_id
      and user_id = v_actor;

    if not found then
      raise exception 'Recipe not found or not owned';
    end if;
  end if;

  delete from public.recipe_ingredients where recipe_id = v_recipe_id;
  delete from public.recipe_steps where recipe_id = v_recipe_id;

  insert into public.recipe_ingredients (recipe_id, position, name, quantity, optional)
  select
    v_recipe_id,
    item.ordinality - 1,
    coalesce(item.value->>'name', ''),
    coalesce(item.value->>'quantity', ''),
    coalesce((item.value->>'optional')::boolean, false)
  from jsonb_array_elements(coalesce(p_ingredients, '[]'::jsonb)) with ordinality as item(value, ordinality);

  insert into public.recipe_steps (recipe_id, position, title, instruction, duration_minutes)
  select
    v_recipe_id,
    item.ordinality - 1,
    coalesce(item.value->>'title', format('Step %s', item.ordinality)),
    coalesce(item.value->>'instruction', ''),
    nullif(item.value->>'duration_minutes', '')::integer
  from jsonb_array_elements(coalesce(p_steps, '[]'::jsonb)) with ordinality as item(value, ordinality);

  return v_recipe_id;
end;
$$;

revoke all on function public.save_recipe_graph(
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
) from public;

grant execute on function public.save_recipe_graph(
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
) to authenticated, service_role;
