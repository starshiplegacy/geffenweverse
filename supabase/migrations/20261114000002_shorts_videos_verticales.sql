-- ===== SHORTS (videos verticales) =====
create table public.shorts (
  id bigint generated always as identity primary key,
  author_id uuid not null references public.profiles (id) on delete cascade,
  video_path text not null,
  caption text check (length(caption) <= 300),
  duracion_seg int check (duracion_seg between 1 and 180),
  created_at timestamptz not null default now()
);
create index shorts_author_idx on public.shorts (author_id, created_at desc);
create index shorts_created_idx on public.shorts (created_at desc);
alter table public.shorts enable row level security;
create policy "ver shorts" on public.shorts for select to authenticated using (true);
create policy "subir short solo Estrella Creadora" on public.shorts for insert to authenticated
  with check ((select auth.uid()) = author_id
    and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.rol = 'estrella'));
create policy "editar mis shorts" on public.shorts for update to authenticated
  using ((select auth.uid()) = author_id) with check ((select auth.uid()) = author_id);
create policy "borrar mis shorts" on public.shorts for delete to authenticated using ((select auth.uid()) = author_id);
grant select, insert, update, delete on public.shorts to authenticated;

-- Starlights y comentarios tambien pueden apuntar a un short
alter table public.starlights add column short_id bigint references public.shorts (id) on delete cascade;
do $$ declare r record; begin
  for r in select conname from pg_constraint where conrelid = 'public.starlights'::regclass and contype = 'c' loop
    execute format('alter table public.starlights drop constraint %I', r.conname);
  end loop;
end $$;
alter table public.starlights add constraint starlights_un_destino check (num_nonnulls(post_id, comment_id, short_id) = 1);
create unique index starlights_short_uidx on public.starlights (user_id, short_id) where short_id is not null;
create index starlights_short_idx on public.starlights (short_id);

alter table public.comments alter column post_id drop not null;
alter table public.comments add column short_id bigint references public.shorts (id) on delete cascade;
alter table public.comments add constraint comments_un_destino check (num_nonnulls(post_id, short_id) = 1);
create index comments_short_idx on public.comments (short_id);

-- Las notificaciones aceptan "short" como objetivo
do $$ declare r record; begin
  for r in select conname from pg_constraint where conrelid = 'public.notifications'::regclass and contype = 'c'
           and pg_get_constraintdef(oid) like '%objetivo%' loop
    execute format('alter table public.notifications drop constraint %I', r.conname);
  end loop;
end $$;
alter table public.notifications add constraint notifications_objetivo_check check (objetivo in ('publicacion','comentario','short'));

create or replace function private.notify_starlight() returns trigger
language plpgsql security definer set search_path = '' as $$
declare dest uuid; obj text;
begin
  if new.post_id is not null then
    select author_id into dest from public.posts where id = new.post_id; obj := 'publicacion';
  elsif new.short_id is not null then
    select author_id into dest from public.shorts where id = new.short_id; obj := 'short';
  else
    select author_id into dest from public.comments where id = new.comment_id; obj := 'comentario';
  end if;
  if dest is not null and dest <> new.user_id then
    insert into public.notifications (user_id, actor_id, tipo, objetivo) values (dest, new.user_id, 'starlight', obj);
  end if;
  return new;
end $$;

create or replace function private.notify_comment() returns trigger
language plpgsql security definer set search_path = '' as $$
declare dest_parent uuid; dest_post uuid; obj text;
begin
  if new.parent_id is not null then
    select author_id into dest_parent from public.comments where id = new.parent_id;
    if dest_parent is not null and dest_parent <> new.author_id then
      insert into public.notifications (user_id, actor_id, tipo, objetivo, texto)
      values (dest_parent, new.author_id, 'respuesta', 'comentario', left(new.texto, 140));
    end if;
  end if;
  if new.post_id is not null then
    select author_id into dest_post from public.posts where id = new.post_id; obj := 'publicacion';
  else
    select author_id into dest_post from public.shorts where id = new.short_id; obj := 'short';
  end if;
  if dest_post is not null and dest_post <> new.author_id and dest_post is distinct from dest_parent then
    insert into public.notifications (user_id, actor_id, tipo, objetivo, texto)
    values (dest_post, new.author_id, 'comentario', obj, left(new.texto, 140));
  end if;
  return new;
end $$;

-- ===== ALMACENAMIENTO DE VIDEOS (bucket publico "shorts", maximo 50 MB por video) =====
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('shorts', 'shorts', true, 52428800, array['video/mp4','video/webm','video/quicktime'])
on conflict (id) do nothing;
create policy "subir videos solo Estrella Creadora" on storage.objects for insert to authenticated
  with check (bucket_id = 'shorts'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.rol = 'estrella'));
create policy "borrar mis videos" on storage.objects for delete to authenticated
  using (bucket_id = 'shorts' and (storage.foldername(name))[1] = (select auth.uid())::text);