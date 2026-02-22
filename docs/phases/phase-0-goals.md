## Phase 0 — Goals & minimal feature list (design)

What we build

* Simple focus timer (Pomodoro-style presets + custom duration).
* Minimal, customizable UI (theme color, font size, 1-screen settings).
* Notifications at timer start/end + optional gentle progress ticks.
* Notifications control: app-level notifications + the option to toggle system Do-Not-Disturb while a session runs.
* Cross-device sync of settings & presets (Supabase auth with Google) so Linux <-> Android keep the same presets.

Why (learning goals)

* Learn Flutter basics (project structure, widgets, state management).
* Learn how to integrate a cloud BaaS (Supabase) and OAuth.
* Learn platform integration for notifications and simple OS-level commands.
