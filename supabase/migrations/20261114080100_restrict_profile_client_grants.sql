-- Least-privilege grants for GeffenWeverse profiles.
-- Keep profile reads for signed-in users; allow edits only to public profile fields.
-- Auth/service-role and database owners retain their administrative privileges.

REVOKE ALL PRIVILEGES ON TABLE public.profiles FROM anon;
REVOKE ALL PRIVILEGES ON TABLE public.profiles FROM authenticated;

GRANT SELECT ON TABLE public.profiles TO authenticated;
GRANT UPDATE (username, display_name, bio, avatar_url)
  ON TABLE public.profiles TO authenticated;
