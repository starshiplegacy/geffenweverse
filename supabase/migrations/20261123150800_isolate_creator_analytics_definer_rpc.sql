alter function public.get_creator_analytics(integer) set schema private;
revoke all on function private.get_creator_analytics(integer) from public;
revoke all on function private.get_creator_analytics(integer) from anon;
grant usage on schema private to authenticated;
grant execute on function private.get_creator_analytics(integer) to authenticated;

create or replace function public.get_creator_analytics(p_days integer default 28)
returns jsonb
language sql
security invoker
set search_path = pg_catalog, public
as $$
  select private.get_creator_analytics(p_days);
$$;
revoke all on function public.get_creator_analytics(integer) from public;
revoke all on function public.get_creator_analytics(integer) from anon;
grant execute on function public.get_creator_analytics(integer) to authenticated;