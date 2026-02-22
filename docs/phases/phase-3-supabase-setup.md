## Phase 3 — Optional: Supabase project + Google auth setup

> **This phase is optional.** The timer works fully offline. Only follow this if you want cross-device settings sync.

What to do

1. Create a Supabase project at [https://app.supabase.com/](https://app.supabase.com/).
2. Enable Google provider in Supabase Dashboard and create OAuth credentials in Google Cloud Console. Set redirect URIs (for local dev use `http://127.0.0.1:54321/auth/v1/callback` as the docs show). See the Supabase Google guide: [https://supabase.com/docs/guides/auth/social-login/auth-google](https://supabase.com/docs/guides/auth/social-login/auth-google).
3. Store credentials in `lib/env.dart`:

   ```
   SUPABASE_URL=...
   SUPABASE_ANON_KEY=...
   ```

Why

* This phase teaches OAuth basics and how Supabase wires social providers — useful knowledge even if the feature is optional.
