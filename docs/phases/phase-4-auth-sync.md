## Phase 4 — Optional: Sign-in & sync (from Settings)

> **This phase is optional.** Requires Phase 3 to be completed first.

What to implement

* Add a "Sign in with Google" button in the **Settings screen** under an "Account & Sync" section.
* Supabase is only initialized when the user taps "Sign in" — the app never blocks on authentication.
* On sign-in, pull settings from Supabase and apply locally. On settings change while signed in, push to Supabase.
* Create a simple `settings` table in Supabase for user presets and theme.
* Show the signed-in email and a "Sign out" button when authenticated.

Notes & references

* Supabase `signInWithOAuth` flow and storing/exchanging session tokens described in the docs.
* All Supabase calls are guarded behind a `_supabaseInitialized` flag so the app never crashes when offline.

Why

* Learn how remote auth/state sync works as an opt-in feature, without forcing it on users.
