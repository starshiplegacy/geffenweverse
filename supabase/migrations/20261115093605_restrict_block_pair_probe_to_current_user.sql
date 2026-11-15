-- Restrict block-pair checks to pairs that include the authenticated caller.
-- This preserves messaging RLS checks while preventing account-to-account block enumeration.
create or replace function private.is_blocked_between(user_a uuid, user_b uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public', 'auth', 'pg_temp'
as $function$
  select
    (select auth.uid()) is not null
    and (
      (select auth.uid()) = user_a
      or (select auth.uid()) = user_b
    )
    and exists (
      select 1
      from public.blocked_users b
      where (b.blocker_id = user_a and b.blocked_id = user_b)
         or (b.blocker_id = user_b and b.blocked_id = user_a)
    );
$function$;
