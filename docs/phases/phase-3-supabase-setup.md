## Phase 3 — Supabase project + Google auth setup

What to do

1. Create a Supabase project at [https://app.supabase.com/](https://app.supabase.com/).
2. Enable Google provider in Supabase Dashboard and create OAuth credentials in Google Cloud Console. Set redirect URIs (for local dev use `http://127.0.0.1:54321/auth/v1/callback` as the docs show). See the Supabase Google guide: [https://supabase.com/docs/guides/auth/social-login/auth-google](https://supabase.com/docs/guides/auth/social-login/auth-google).
3. Store client id/secret in Supabase project settings or use environment variables for local dev:

   ```
   SUPABASE_URL=...
   SUPABASE_ANON_KEY=...
   SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET="your-secret"
   ```

Why

* This phase teaches OAuth basics and how Supabase wires social providers for syncing user data between devices.
