-- GeffenWeverse: protect profile role assignment.
-- Existing users keep their current roles; new profiles default to astroturista.
-- The role may only be changed by trusted server-side/admin execution
-- (Postgres migrations or the server-side service_role), never by a client JWT.

ALTER TABLE public.profiles
  ALTER COLUMN rol SET DEFAULT 'astroturista';

CREATE OR REPLACE FUNCTION private.prevent_profile_role_escalation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF NEW.rol IS DISTINCT FROM OLD.rol
     AND current_user NOT IN ('postgres', 'service_role') THEN
    RAISE EXCEPTION 'No tienes permiso para modificar el rol del perfil.'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.prevent_profile_role_escalation()
  FROM PUBLIC, anon, authenticated, service_role;

CREATE TRIGGER profiles_prevent_role_escalation
  BEFORE UPDATE OF rol ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION private.prevent_profile_role_escalation();

-- Profile creation is handled by the trusted Auth trigger
-- (private.handle_new_user), not by direct client inserts.
REVOKE INSERT ON TABLE public.profiles FROM anon, authenticated;
