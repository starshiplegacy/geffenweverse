create or replace function public.get_creator_analytics(p_days integer default 28)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user uuid := auth.uid();
  v_days integer := greatest(7, least(coalesce(p_days, 28), 90));
  v_result jsonb;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  with owned_content as (
    select p.id, 'post'::text as content_type, coalesce(p.titulo,p.texto,'Publicación') as title, p.created_at
    from public.posts p where p.author_id=v_user
    union all
    select s.id, 'short'::text, coalesce(s.caption,'Short'), s.created_at
    from public.shorts s where s.author_id=v_user
  ),
  event_summary as (
    select count(*) filter(where e.event_type='impression') as impressions,
           count(distinct e.actor_id) filter(where e.event_type='impression') as reach,
           count(*) filter(where e.event_type='view_start') as views,
           count(*) filter(where e.event_type='view_complete') as completions
    from public.creator_events e join owned_content c
      on c.content_type=e.content_type and c.id=e.content_id
    where e.occurred_at >= now()-make_interval(days=>v_days)
  ),
  daily as (
    select d.day::date as day,
      count(e.id) filter(where e.event_type='impression') as impressions,
      count(e.id) filter(where e.event_type='view_start') as views,
      count(e.id) filter(where e.event_type='view_complete') as completions
    from generate_series(current_date-(v_days-1),current_date,interval '1 day') d(day)
    left join public.creator_events e on e.occurred_day=d.day::date
      and e.occurred_at>=now()-make_interval(days=>v_days)
      and exists(select 1 from owned_content c where c.content_type=e.content_type and c.id=e.content_id)
    group by d.day
  ),
  per_content as (
    select c.id,c.content_type,c.title,c.created_at,
      coalesce((select count(*) from public.creator_events e where e.content_type=c.content_type and e.content_id=c.id and e.event_type='impression' and e.occurred_at>=now()-make_interval(days=>v_days)),0) as impressions,
      coalesce((select count(distinct e.actor_id) from public.creator_events e where e.content_type=c.content_type and e.content_id=c.id and e.event_type='impression' and e.occurred_at>=now()-make_interval(days=>v_days)),0) as reach,
      coalesce((select count(*) from public.creator_events e where e.content_type=c.content_type and e.content_id=c.id and e.event_type='view_start' and e.occurred_at>=now()-make_interval(days=>v_days)),0) as views,
      coalesce((select count(*) from public.starlights st where ((c.content_type='post' and st.post_id=c.id) or (c.content_type='short' and st.short_id=c.id)) and st.created_at>=now()-make_interval(days=>v_days)),0) as starlights,
      coalesce((select count(*) from public.comments cm where ((c.content_type='post' and cm.post_id=c.id) or (c.content_type='short' and cm.short_id=c.id)) and cm.created_at>=now()-make_interval(days=>v_days)),0) as comments
    from owned_content c
  )
  select jsonb_build_object(
    'period_days',v_days,
    'summary',jsonb_build_object(
      'posts',(select count(*) from public.posts where author_id=v_user),
      'shorts',(select count(*) from public.shorts where author_id=v_user),
      'followers',(select count(*) from public.follows where following_id=v_user),
      'fan_clubs',(select count(*) from public.community_members where user_id=v_user),
      'impressions',(select impressions from event_summary),
      'reach',(select reach from event_summary),
      'views',(select views from event_summary),
      'completions',(select completions from event_summary),
      'starlights',(select count(*) from public.starlights st where (exists(select 1 from owned_content c where c.content_type='post' and st.post_id=c.id) or exists(select 1 from owned_content c where c.content_type='short' and st.short_id=c.id)) and st.created_at>=now()-make_interval(days=>v_days)),
      'comments',(select count(*) from public.comments cm where (exists(select 1 from owned_content c where c.content_type='post' and cm.post_id=c.id) or exists(select 1 from owned_content c where c.content_type='short' and cm.short_id=c.id)) and cm.created_at>=now()-make_interval(days=>v_days))
    ),
    'daily',coalesce((select jsonb_agg(jsonb_build_object('day',day,'impressions',impressions,'views',views,'completions',completions) order by day) from daily),'[]'::jsonb),
    'content',coalesce((select jsonb_agg(jsonb_build_object('id',id,'type',content_type,'title',title,'created_at',created_at,'impressions',impressions,'reach',reach,'views',views,'starlights',starlights,'comments',comments) order by created_at desc) from (select * from per_content order by created_at desc limit 60) x),'[]'::jsonb)
  ) into v_result;
  return coalesce(v_result,'{}'::jsonb);
end;
$$;
revoke all on function public.get_creator_analytics(integer) from public;
revoke all on function public.get_creator_analytics(integer) from anon;
grant execute on function public.get_creator_analytics(integer) to authenticated;