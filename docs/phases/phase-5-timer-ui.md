## Phase 5 — Timer core & UI (the app)

What to implement

* Main screen: big timer display, Start / Pause / Reset buttons, quick-presets (25/5, 50/10), and a small settings icon.
* Settings screen: theme color picker (3 choices), default duration, toggle sound/vibration, toggle "change system DND while running".
* Basic architecture: `StatefulWidget` for timer screen; keep state local and persist settings to `shared_preferences` and to Supabase when signed-in.

Learning focus

* Flutter widgets: `Scaffold`, `AppBar`, `AnimatedContainer`, `Stream.periodic` or `Timer.periodic`.
* Managing lifecycle (pause/resume) and platform channels if needed.

Why

* Teaches core Flutter UI concepts and the event loop for timers.
