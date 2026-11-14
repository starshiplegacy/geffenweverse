-- The RLS auto-enable function is invoked by a database event trigger.
-- Client roles and service_role do not need direct EXECUTE permission.
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable()
  FROM PUBLIC, anon, authenticated, service_role;
