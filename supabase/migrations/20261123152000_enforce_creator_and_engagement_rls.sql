drop policy if exists shorts_enforce_creator_and_moderation on public.shorts;
create policy shorts_enforce_creator_and_moderation on public.shorts as restrictive for insert to authenticated with check (
  author_id = (select auth.uid()) and public.geffen_user_can_post()
  and (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.rol='estrella') or public.is_geffen_whitelisted())
);
drop policy if exists comments_enforce_author_and_moderation on public.comments;
create policy comments_enforce_author_and_moderation on public.comments as restrictive for insert to authenticated with check (
  author_id=(select auth.uid()) and public.geffen_user_can_post() and not public.geffen_user_is_suspended()
);
drop policy if exists starlights_enforce_owner_and_moderation on public.starlights;
create policy starlights_enforce_owner_and_moderation on public.starlights as restrictive for insert to authenticated with check (
  user_id=(select auth.uid()) and not public.geffen_user_is_suspended()
);
drop policy if exists creator_events_no_self_view on public.creator_events;
create policy creator_events_no_self_view on public.creator_events as restrictive for insert to authenticated with check (
  actor_id=(select auth.uid()) and (
    (content_type='post' and exists(select 1 from public.posts p where p.id=content_id and p.author_id<>(select auth.uid())))
    or (content_type='short' and exists(select 1 from public.shorts s where s.id=content_id and s.author_id<>(select auth.uid())))
  )
);