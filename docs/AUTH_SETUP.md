# GeffenWeverse — Supabase Auth setup

This frontend uses Supabase Auth email/password with the pinned browser SDK `@supabase/supabase-js@2.119.0`.

## Connected project

- Project ref: `uyhcocdknweqvcqgbnez`
- API URL: `https://uyhcocdknweqvcqgbnez.supabase.co`
- Browser key: publishable key only (safe for browser use when RLS is enabled)
- Never add a `service_role` or secret key to this HTML file.

## Supabase Dashboard configuration

Before testing registration, email confirmation, or password recovery:

1. Open **Authentication → Providers → Email** and make sure email/password sign-in is enabled.
2. Keep email confirmation enabled for normal account registration.
3. Open **Authentication → URL Configuration**.
4. Set the **Site URL** to the canonical production URL once the site is deployed.
5. Add each development and production origin to **Redirect URLs**. Examples for local testing:
   - `http://localhost:5500/**`
   - `http://127.0.0.1:5500/**`
   Replace the port with the one used by the local static server.
6. Configure a reliable custom SMTP provider before public launch. Verify confirmation and recovery templates deliver to real users.
7. Set the minimum password length to at least 8 characters.

The frontend uses the current page origin as the email confirmation and password-recovery redirect. The exact origin must be present in the Redirect URLs allow-list. The final production URL is not set here because GeffenWeverse has not been deployed yet.

## Implemented flows

- Registration with display name, email, password, and confirmation.
- Email confirmation when required by the project Auth settings.
- Password login via `signInWithPassword`.
- Persistent browser session, automatic token refresh, and URL session detection.
- Password recovery via `resetPasswordForEmail`, followed by `updateUser({ password })`.
- Local-session logout via `signOut({ scope: 'local' })`.
- Authenticated-route guard in the single-page hash router.
- Profile load from `public.profiles` after authentication.
- New profiles are created by the existing `auth.users` trigger and receive the database default role `astroturista`.
- The browser never chooses or writes the account role. `estrella` is an administrative assignment.

## Verification checklist

Use a real test mailbox and two separate test accounts:

1. Register a new account and confirm its email.
2. Verify exactly one `public.profiles` row exists for its Auth user ID.
3. Verify its role is `astroturista`.
4. Sign out, sign back in, and reload the page; the session should persist.
5. Request a password reset, open the email link, and set a new password.
6. Sign in with the new password.
7. Sign out and verify protected pages return to the login screen.
8. Verify the browser cannot update `profiles.rol` through the Data API.

Social OAuth buttons are intentionally not presented as active until their providers and callback URLs are configured in Supabase.
