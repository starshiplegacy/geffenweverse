create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  badge_key text not null check (badge_key in ('verified_creator_star','verified_plan_paid')),
  awarded_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  awarded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists user_badges_user_active_idx
  on public.user_badges (user_id, badge_key)
  where revoked_at is null;

alter table public.user_badges enable row level security;

create policy "Active badges are visible to signed-in users"
  on public.user_badges
  for select
  to authenticated
  using (revoked_at is null and (expires_at is null or expires_at > now()));

revoke all on table public.user_badges from anon, authenticated;
grant select on table public.user_badges to authenticated;
