## Phase 4 — Implement authentication + sync

What to implement

* Add `supabase_flutter` to the app and initialize in `main()` with your URL and anon key.
* Implement "Sign in with Google" using Supabase `signInWithOAuth({ provider: 'google' })`. Handle the redirect/callback and save session locally.
* Create a simple `settings` table in Supabase for user presets and theme; sync on sign-in and on settings change.

Notes & references

* Supabase `signInWithOAuth` flow and storing/exchanging session tokens described in the docs. Use `exchangeCodeForSession` if needed.

Why

* Learn how remote auth/state sync works and how to persist user preferences in the cloud so your Linux and Android apps match.
