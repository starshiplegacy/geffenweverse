-- Esquema privado para funciones con privilegios (no expuesto por la API)
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- ===== PERFILES Y AJUSTES =====
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,30}$'),
  display_name text,
  bio text,
  avatar_url text,
  rol text not null default 'astroturista' check (rol in ('astroturista','estrella')),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
create policy "perfiles visibles para usuarios" on public.profiles for select to authenticated using (true);
create policy "editar mi perfil" on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create table public.user_settings (
  user_id uuid primary key references auth.users (id) on delete cascade,
  idioma_servicio text not null default 'español (latino)',
  idioma_traducido text not null default '',
  traducir_auto boolean not null default false,
  tema text not null default 'device' check (tema in ('light','dark','device')),
  radio_fm boolean not null default true,
  n_eventos boolean not null default true,
  n_promos boolean not null default true,
  n_artistas boolean not null default true,
  n_pedidos boolean not null default true,
  p_anuncios boolean not null default true,
  p_servicios boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.user_settings enable row level security;
create policy "ver mis ajustes" on public.user_settings for select to authenticated using ((select auth.uid()) = user_id);
create policy "editar mis ajustes" on public.user_settings for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- Al registrarse alguien se crean su perfil y sus ajustes
create function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, username)
  values (new.id, 'user_' || substr(replace(new.id::text, '-', ''), 1, 10));
  insert into public.user_settings (user_id) values (new.id);
  return new;
end $$;
revoke all on function private.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function private.handle_new_user();

-- ===== SEGUIDORES =====
create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);
create index follows_following_idx on public.follows (following_id);
alter table public.follows enable row level security;
create policy "ver seguidores" on public.follows for select to authenticated using (true);
create policy "seguir" on public.follows for insert to authenticated with check ((select auth.uid()) = follower_id);
create policy "dejar de seguir" on public.follows for delete to authenticated using ((select auth.uid()) = follower_id);

-- ===== ARTISTAS Y COMUNIDADES =====
create table public.artists (
  slug text primary key,
  nombre text not null,
  tipo text not null,
  orden int not null default 0,
  activo boolean not null default true
);
alter table public.artists enable row level security;
create policy "artistas publicos" on public.artists for select to anon, authenticated using (activo);

create table public.community_members (
  user_id uuid not null references auth.users (id) on delete cascade,
  artist_slug text not null references public.artists (slug) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (user_id, artist_slug)
);
create index community_members_artist_idx on public.community_members (artist_slug);
alter table public.community_members enable row level security;
create policy "ver mis comunidades" on public.community_members for select to authenticated using ((select auth.uid()) = user_id);
create policy "unirme a una comunidad" on public.community_members for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "salir de una comunidad" on public.community_members for delete to authenticated using ((select auth.uid()) = user_id);

-- ===== PUBLICACIONES, COMENTARIOS Y STARLIGHTS =====
create table public.posts (
  id bigint generated always as identity primary key,
  author_id uuid not null references public.profiles (id) on delete cascade,
  tipo text not null check (tipo in ('foto','video','post')),
  texto text,
  media_url text,
  created_at timestamptz not null default now()
);
create index posts_author_idx on public.posts (author_id, created_at desc);
alter table public.posts enable row level security;
create policy "ver publicaciones" on public.posts for select to authenticated using (true);
create policy "publicar solo Estrella Creadora" on public.posts for insert to authenticated
  with check ((select auth.uid()) = author_id
    and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.rol = 'estrella'));
create policy "editar mis publicaciones" on public.posts for update to authenticated
  using ((select auth.uid()) = author_id) with check ((select auth.uid()) = author_id);
create policy "borrar mis publicaciones" on public.posts for delete to authenticated using ((select auth.uid()) = author_id);

create table public.comments (
  id bigint generated always as identity primary key,
  post_id bigint not null references public.posts (id) on delete cascade,
  parent_id bigint references public.comments (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  texto text not null check (length(texto) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index comments_post_idx on public.comments (post_id);
create index comments_parent_idx on public.comments (parent_id);
create index comments_author_idx on public.comments (author_id);
alter table public.comments enable row level security;
create policy "ver comentarios" on public.comments for select to authenticated using (true);
create policy "comentar" on public.comments for insert to authenticated with check ((select auth.uid()) = author_id);
create policy "borrar mis comentarios" on public.comments for delete to authenticated using ((select auth.uid()) = author_id);

create table public.starlights (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  post_id bigint references public.posts (id) on delete cascade,
  comment_id bigint references public.comments (id) on delete cascade,
  created_at timestamptz not null default now(),
  check ((post_id is null) <> (comment_id is null))
);
create unique index starlights_post_uidx on public.starlights (user_id, post_id) where post_id is not null;
create unique index starlights_comment_uidx on public.starlights (user_id, comment_id) where comment_id is not null;
create index starlights_post_idx on public.starlights (post_id);
create index starlights_comment_idx on public.starlights (comment_id);
alter table public.starlights enable row level security;
create policy "ver starlights" on public.starlights for select to authenticated using (true);
create policy "dar starlight" on public.starlights for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "quitar mi starlight" on public.starlights for delete to authenticated using ((select auth.uid()) = user_id);

-- ===== NOTIFICACIONES (las crean los triggers) =====
create table public.notifications (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  actor_id uuid not null references public.profiles (id) on delete cascade,
  tipo text not null check (tipo in ('follow','starlight','comentario','respuesta')),
  objetivo text check (objetivo in ('publicacion','comentario')),
  texto text,
  leida boolean not null default false,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_actor_idx on public.notifications (actor_id);
alter table public.notifications enable row level security;
create policy "ver mis notificaciones" on public.notifications for select to authenticated using ((select auth.uid()) = user_id);
create policy "marcar como leida" on public.notifications for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "borrar mis notificaciones" on public.notifications for delete to authenticated using ((select auth.uid()) = user_id);

create function private.notify_follow() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.notifications (user_id, actor_id, tipo) values (new.following_id, new.follower_id, 'follow');
  return new;
end $$;
create trigger follows_notify after insert on public.follows for each row execute function private.notify_follow();

create function private.notify_starlight() returns trigger
language plpgsql security definer set search_path = '' as $$
declare dest uuid; obj text;
begin
  if new.post_id is not null then
    select author_id into dest from public.posts where id = new.post_id; obj := 'publicacion';
  else
    select author_id into dest from public.comments where id = new.comment_id; obj := 'comentario';
  end if;
  if dest is not null and dest <> new.user_id then
    insert into public.notifications (user_id, actor_id, tipo, objetivo) values (dest, new.user_id, 'starlight', obj);
  end if;
  return new;
end $$;
create trigger starlights_notify after insert on public.starlights for each row execute function private.notify_starlight();

create function private.notify_comment() returns trigger
language plpgsql security definer set search_path = '' as $$
declare dest_parent uuid; dest_post uuid;
begin
  if new.parent_id is not null then
    select author_id into dest_parent from public.comments where id = new.parent_id;
    if dest_parent is not null and dest_parent <> new.author_id then
      insert into public.notifications (user_id, actor_id, tipo, objetivo, texto)
      values (dest_parent, new.author_id, 'respuesta', 'comentario', left(new.texto, 140));
    end if;
  end if;
  select author_id into dest_post from public.posts where id = new.post_id;
  if dest_post is not null and dest_post <> new.author_id and dest_post is distinct from dest_parent then
    insert into public.notifications (user_id, actor_id, tipo, objetivo, texto)
    values (dest_post, new.author_id, 'comentario', 'publicacion', left(new.texto, 140));
  end if;
  return new;
end $$;
create trigger comments_notify after insert on public.comments for each row execute function private.notify_comment();

revoke all on function private.notify_follow(), private.notify_starlight(), private.notify_comment() from public, anon, authenticated;

-- ===== MENU: eventos, codigos, cupones, anuncios, FAQ =====
create table public.event_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  evento text not null check (length(evento) between 1 and 80),
  mensaje text check (length(mensaje) <= 300),
  estado text not null default 'Pendiente',
  created_at timestamptz not null default now()
);
create index event_requests_user_idx on public.event_requests (user_id);
alter table public.event_requests enable row level security;
create policy "ver mis solicitudes" on public.event_requests for select to authenticated using ((select auth.uid()) = user_id);
create policy "enviar solicitud" on public.event_requests for insert to authenticated with check ((select auth.uid()) = user_id);

-- Codigos digitales: sin acceso desde la API; se canjean con una funcion de servidor
create table public.digital_codes (
  codigo text primary key,
  titulo text not null,
  canjeado_por uuid references auth.users (id) on delete set null,
  canjeado_at timestamptz
);
create index digital_codes_user_idx on public.digital_codes (canjeado_por);
alter table public.digital_codes enable row level security;

create table public.purchased_media (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  codigo text not null,
  titulo text not null,
  created_at timestamptz not null default now(),
  unique (user_id, codigo)
);
alter table public.purchased_media enable row level security;
create policy "ver mi multimedia" on public.purchased_media for select to authenticated using ((select auth.uid()) = user_id);

create table public.coupons (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  codigo text not null,
  descripcion text,
  vence date,
  created_at timestamptz not null default now()
);
create index coupons_user_idx on public.coupons (user_id);
alter table public.coupons enable row level security;
create policy "ver mis cupones" on public.coupons for select to authenticated using ((select auth.uid()) = user_id);

create table public.announcements (
  id bigint generated always as identity primary key,
  titulo text not null,
  texto text not null,
  created_at timestamptz not null default now()
);
alter table public.announcements enable row level security;
create policy "anuncios publicos" on public.announcements for select to anon, authenticated using (true);

create table public.faq (
  id bigint generated always as identity primary key,
  orden int not null default 0,
  pregunta text not null,
  respuesta text not null
);
alter table public.faq enable row level security;
create policy "faq publico" on public.faq for select to anon, authenticated using (true);

-- ===== TIENDA: Starship Legacy Shop (pagos con PayPal) =====
create table public.products (
  id uuid primary key default gen_random_uuid(),
  cat text not null,
  nombre text not null,
  precio numeric(10,2) not null check (precio >= 0),
  activo boolean not null default true,
  created_at timestamptz not null default now()
);
create index products_cat_idx on public.products (cat);
alter table public.products enable row level security;
create policy "productos publicos" on public.products for select to anon, authenticated using (activo);

create table public.wishlist (
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  seleccionado boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);
create index wishlist_product_idx on public.wishlist (product_id);
alter table public.wishlist enable row level security;
create policy "ver mi lista de deseos" on public.wishlist for select to authenticated using ((select auth.uid()) = user_id);
create policy "guardar en mi lista" on public.wishlist for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "editar mi lista" on public.wishlist for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "quitar de mi lista" on public.wishlist for delete to authenticated using ((select auth.uid()) = user_id);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  estado text not null default 'Pendiente de pago',
  total numeric(10,2) not null check (total >= 0),
  metodo text not null default 'PayPal',
  paypal_order_id text unique,
  created_at timestamptz not null default now()
);
create index orders_user_idx on public.orders (user_id);
alter table public.orders enable row level security;
create policy "ver mis pedidos" on public.orders for select to authenticated using ((select auth.uid()) = user_id);

create table public.order_items (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  nombre text not null,
  precio numeric(10,2) not null,
  cantidad int not null default 1 check (cantidad > 0)
);
create index order_items_order_idx on public.order_items (order_id);
create index order_items_product_idx on public.order_items (product_id);
alter table public.order_items enable row level security;
create policy "ver articulos de mis pedidos" on public.order_items for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_id and o.user_id = (select auth.uid())));

-- ===== PERMISOS DE LA API (minimos; RLS decide las filas) =====
grant select on public.artists, public.announcements, public.faq, public.products to anon, authenticated;
grant select, update on public.profiles, public.user_settings to authenticated;
grant select, insert, delete on public.follows, public.community_members, public.comments, public.starlights to authenticated;
grant select, insert, update, delete on public.posts, public.wishlist to authenticated;
grant select, delete on public.notifications to authenticated;
grant update (leida) on public.notifications to authenticated;
grant select on public.event_requests, public.purchased_media, public.coupons, public.orders, public.order_items to authenticated;
grant insert (user_id, evento, mensaje) on public.event_requests to authenticated;

-- ===== DATOS INICIALES =====
insert into public.artists (slug, nombre, tipo, orden) values
  ('kim-heewon','Kim Heewon','Cantante y Actriz',1),
  ('njz','NJZ','Grupo Musical',2),
  ('sbc','SBC','Grupo Musical',3),
  ('kiss-of-heaven','KISS OF HEAVEN','Grupo Musical',4),
  ('pink-pop','Pink Pop','Grupo Musical',5),
  ('got','GOT','Grupo Musical',6);

insert into public.announcements (titulo, texto) values
  ('¡Bienvenido a GeffenWeverse!','Aquí publicaremos las novedades del conglomerado Starship Legacy.');

insert into public.faq (orden, pregunta, respuesta) values
  (1,'1 - ¿Qué es Starship Legacy?','Starship es un conglomerado multifacético e internacional: no solo distribuye música y firma artistas, también es una academia, un estudio, una producción, un concepto, una plataforma de streaming, una comunidad, una tienda virtual y física, Fandom x Artista y Artista x Fandom, y mucho más, porque todos somos uno y uno somos todos.'),
  (2,'2 - ¿Puedo estar en STARSHIP?','Claro que puedes. Existen dos formas: la academia, donde pagas $3 dólares la mensualidad, virtual internacional y presencial solo en República Dominicana. Si eres dominicano y quieres estudiar virtual, lo puedes hacer. Llena el formulario que aparece en: <a href="https://starship-ent.org" target="_blank" rel="noopener">starship-ent.org</a>'),
  (3,'3 - ¿Puedo trabajar en STARSHIP?','Claro que puedes. Llena el formulario que aparece en: <a href="https://starship-ent.org" target="_blank" rel="noopener">starship-ent.org</a>. Llena los datos, acepta los requisitos y envía.'),
  (4,'4 - ¿Soy artista independiente y quiero colaborar con un artista, modelo y/o actriz/actor?','Claro que sí puedes. Ponte en contacto con el chatbot que está en la parte inferior derecha de <a href="https://starship-ent.org" target="_blank" rel="noopener">starship-ent.org</a> y díselo, te guiará.'),
  (5,'5 - ¿Dudas, quejas o sugerencias?','Comunícate con nuestro soporte en X: <a href="https://x.com/starship_faq" target="_blank" rel="noopener">https://x.com/starship_faq</a>'),
  (6,'6 - ¿Notas que algún usuario en esta app/web u otra se hace pasar por un artista (o sufre acoso o ciberbullying)?','Manda capturas y nombres de usuario (“@”). ¡Nuestros artistas están siempre protegidos!');