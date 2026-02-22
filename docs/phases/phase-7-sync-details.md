## Phase 7 — Sync details, conflict strategy & background

What to implement

* On setting change, write to Supabase `settings` table: `{ user_id, key, value, updated_at }`.
* Simple conflict resolution: last-write-wins using `updated_at`.
* On sign-in on another device, read settings and apply locally.
* Optionally use Supabase realtime to push updates, but for v1 polling on app start and after changes is fine.

Why

* Teaches cloud sync basics and simple conflict handling without complex CRDTs.
