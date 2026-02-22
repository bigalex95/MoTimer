# Tech stack (short)

Flutter, Supabase, Google, Android, Linux, Antigravity, Agentic

Below is a clear, phase-by-phase implementation plan you can follow and paste into Antigravity / Agentic workflows. Each phase lists *what* we implement, *how* to do it (commands / links), and *why* (learning goals). I also include ready-to-paste prompts for Antigravity and Agentic at the end.

---

# Implementation plan — phases (simple focus timer + DND + Supabase sync)

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

---

## Phase 1 — Dev environment (Linux + Android)

What to do (commands + links)

1. Install Flutter SDK and desktop prerequisites on Linux (Ubuntu example):

   * Follow official docs: [https://docs.flutter.dev/platform-integration/linux/setup](https://docs.flutter.dev/platform-integration/linux/setup) and [https://docs.flutter.dev/install](https://docs.flutter.dev/install). ([docs.flutter.dev][1])
   * Example (Ubuntu/Debian):

     ```
     sudo apt update
     sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
     # download flutter sdk, extract, add to PATH per docs
     ```
2. Android setup (Android SDK / platform-tools / emulator or device): follow Flutter Android setup: [https://docs.flutter.dev/platform-integration/android/setup](https://docs.flutter.dev/platform-integration/android/setup). Then run:

   ```
   flutter doctor
   flutter devices
   ```

   Install Android Studio or SDK tools as instructed. ([docs.flutter.dev][2])

Why

* `flutter doctor` will teach you how Flutter diagnoses missing pieces. This phase gets your environment ready to run both Linux desktop and Android builds.

---

## Phase 2 — Project scaffold & basic packages

What to implement

* Create project and add minimal dependencies:

  ```
  flutter create focus_timer
  cd focus_timer
  ```
* Add packages in `pubspec.yaml`:

  * `supabase_flutter` (Supabase client)
  * `flutter_local_notifications` (local notifications)
  * `shared_preferences` (local settings)
  * (optional) `provider` or `riverpod` (simple state mgmt — keep it minimal; using `setState` is ok for v1)

Useful links (plain text)

* Flutter packages list: [https://pub.dev/](https://pub.dev/)
* flutter_local_notifications: [https://pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications). ([Dart packages][3])

Why

* This phase teaches adding packages, dependency management, and the pattern for wiring third-party SDKs into Flutter.

---

## Phase 3 — Supabase project + Google auth setup

What to do

1. Create a Supabase project at [https://app.supabase.com/](https://app.supabase.com/).
2. Enable Google provider in Supabase Dashboard and create OAuth credentials in Google Cloud Console. Set redirect URIs (for local dev use `http://127.0.0.1:54321/auth/v1/callback` as the docs show). See the Supabase Google guide: [https://supabase.com/docs/guides/auth/social-login/auth-google](https://supabase.com/docs/guides/auth/social-login/auth-google). ([Supabase][4])
3. Store client id/secret in Supabase project settings or use environment variables for local dev:

   ```
   SUPABASE_URL=...
   SUPABASE_ANON_KEY=...
   SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_SECRET="your-secret"
   ```

Why

* This phase teaches OAuth basics and how Supabase wires social providers for syncing user data between devices.

---

## Phase 4 — Implement authentication + sync

What to implement

* Add `supabase_flutter` to the app and initialize in `main()` with your URL and anon key.
* Implement "Sign in with Google" using Supabase `signInWithOAuth({ provider: 'google' })`. Handle the redirect/callback and save session locally.
* Create a simple `settings` table in Supabase for user presets and theme; sync on sign-in and on settings change.

Notes & references

* Supabase `signInWithOAuth` flow and storing/exchanging session tokens described in the docs. Use `exchangeCodeForSession` if needed. ([Supabase][4])

Why

* Learn how remote auth/state sync works and how to persist user preferences in the cloud so your Linux and Android apps match.

---

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

---

## Phase 6 — Notifications & Do-Not-Disturb behavior

What to implement

1. Local notifications: use `flutter_local_notifications` to show a notification at timer end (and optionally when started). Read the plugin docs: [https://pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications). ([Dart packages][3])
2. Android DND behavior:

   * Android requires the `ACCESS_NOTIFICATION_POLICY` permission to change global DND. The user must grant this in Settings (cannot be silently granted). In your app:

     * Add `android.permission.ACCESS_NOTIFICATION_POLICY` to `AndroidManifest.xml`.
     * Check `NotificationManager.isNotificationPolicyAccessGranted()` and, if not granted, open the settings screen:

       ```java
       startActivity(new Intent(android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS));
       ```
     * If granted, you can call `NotificationManager.setInterruptionFilter(...)` to set zen mode. See Android docs on `NotificationManager` and `setInterruptionFilter`. ([Android Developers][5])
3. Linux desktop DND:

   * Many Linux desktops (GNOME) expose a GSettings key for DND. You can toggle `"org.gnome.desktop.notifications" show-banners` with `gsettings`:

     ```
     gsettings set org.gnome.desktop.notifications show-banners false
     gsettings set org.gnome.desktop.notifications show-banners true
     ```

     * Run these from Dart via `Process.run()` when the user allows it. Note: different desktop environments behave differently; implement GNOME support and fall back to app-only suppression. See examples: [https://jyn.dev/do-not-disturb-in-gnome/](https://jyn.dev/do-not-disturb-in-gnome/) and askubuntu instructions. ([jyn.dev][6])

Safety & UX note

* Because toggling global DND changes system behavior, always request explicit consent and show a clear dialog. On Android, open the system settings and ask the user to grant DND access.

Why

* Teaches you platform integration and permission flows. You’ll learn how to do small native interactions from Flutter.

---

## Phase 7 — Sync details, conflict strategy & background

What to implement

* On setting change, write to Supabase `settings` table: `{ user_id, key, value, updated_at }`.
* Simple conflict resolution: last-write-wins using `updated_at`.
* On sign-in on another device, read settings and apply locally.
* Optionally use Supabase realtime to push updates, but for v1 polling on app start and after changes is fine.

Why

* Teaches cloud sync basics and simple conflict handling without complex CRDTs.

---

## Phase 8 — Build, test & release

What to do

* Test on Android physical device (enable USB debugging) and on Linux desktop (`flutter run -d linux`).
* Build Android APK / appbundle and Linux release binary:

  ```
  flutter build apk --release
  flutter build linux --release
  ```
* Polish UI / accessibility / icons.

Why

* Teaches building and packaging for two targets.

---

# Quick development checklist (one-liner tasks you can tick)

1. Install Flutter & Android SDK (run `flutter doctor`) — DONE
2. `flutter create focus_timer` — DONE
3. Add `supabase_flutter`, `flutter_local_notifications`, `shared_preferences` — DONE
4. Create Supabase project + enable Google provider — DONE (Supabase docs: [https://supabase.com/docs/guides/auth/social-login/auth-google](https://supabase.com/docs/guides/auth/social-login/auth-google)). ([Supabase][4])
5. Implement sign-in & settings sync — DONE
6. Implement timer UI + local notifications — DONE (see plugin docs). ([Dart packages][3])
7. Implement DND toggles (Android: open settings + request; Linux GNOME via gsettings) — DONE. ([Android Developers][5])

---

# Useful plain-text links (copy-paste)

* Flutter install / Linux setup: [https://docs.flutter.dev/platform-integration/linux/setup](https://docs.flutter.dev/platform-integration/linux/setup)
* Flutter install: [https://docs.flutter.dev/install](https://docs.flutter.dev/install)
* Flutter Android setup: [https://docs.flutter.dev/platform-integration/android/setup](https://docs.flutter.dev/platform-integration/android/setup)
* Supabase Google login: [https://supabase.com/docs/guides/auth/social-login/auth-google](https://supabase.com/docs/guides/auth/social-login/auth-google)
* flutter_local_notifications: [https://pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
* GNOME DND (gsettings): [https://jyn.dev/do-not-disturb-in-gnome/](https://jyn.dev/do-not-disturb-in-gnome/)
* AskUbuntu toggle DND CLI example: [https://askubuntu.com/questions/1267256/is-there-a-way-to-toggle-do-not-disturb-from-the-commandline](https://askubuntu.com/questions/1267256/is-there-a-way-to-toggle-do-not-disturb-from-the-commandline)

---

# Ready-to-use prompts

### Antigravity (autonomous helper) — implement-by-phase prompt

```
Goal: Implement a minimal cross-platform Focus Timer app using Flutter (Linux desktop + Android). Keep UI simple & customizable; add local notifications and optional system Do-Not-Disturb toggling; add Supabase Google auth for syncing settings.
Constraints:
- Use Flutter as framework.
- Keep UI to two main screens: Timer and Settings.
- Use supabase_flutter for auth/sync and flutter_local_notifications for local notifications.
- On Android, request ACCESS_NOTIFICATION_POLICY via settings flow if user enables DND toggle.
- On Linux (GNOME) toggle DND via `gsettings set org.gnome.desktop.notifications show-banners false/true` when available; otherwise limit to app-level suppression.
- No extraneous features; minimal permissions & clear user consent for DND changes.
Deliverables per phase:
- Phase 1: repo skeleton + README with setup steps and `flutter doctor` output.
- Phase 2: pubspec.yaml with dependencies and working `flutter run` on Linux.
- Phase 3: Supabase project guide notes + sample env var file.
- Phase 4: Implement sign-in (Google) with a simple login screen and persist session.
- Phase 5: Timer UI + start/pause/reset + local notifications at end.
- Phase 6: DND toggle implementation (Android settings flow + GNOME gsettings toggle).
- Phase 7: Sync settings with Supabase; simple last-write-wins.
- Phase 8: Build instructions and one test report (Linux + Android).
Operational rules:
- Create small commits per phase with clear messages.
- Add short code comments (2–3 lines) explaining platform-specific choices.
- Before making changes to users' machines (e.g., toggling DND), create a UI confirmation and require explicit permission.
- After each phase, open a draft PR and produce a short summary and test checklist.
Return:
- For each phase, produce code diffs, run instructions, and a short explanation of what I learned.
```

### Agentic mode (step-runner / human-directed) — run this with human checkpoints

```
Task: Help me implement the Focus Timer app step-by-step. You may run commands locally or instruct me, but ask for confirmation before applying any change that modifies system settings or requires granting special permissions (DND).
Steps:
1. Provide exact commands to install Flutter and Android SDK for Ubuntu.
2. Create the Flutter app skeleton and push to a new git repo.
3. Add dependencies and run `flutter pub get` — show output.
4. Create Supabase project draft and list required redirect URIs and env vars.
5. Implement UI scaffolding and provide the code file for Timer screen.
6. Implement sign-in flow using supabase_flutter; provide test steps to verify sign-in.
7. Implement local notifications integration and a test case to ensure notifications deliver on Android and Linux.
8. Implement DND toggle with clear permission flow: 
   - Android: check & open settings for DND access (do not change settings automatically).
   - Linux GNOME: preview `gsettings` toggle command and request explicit approval before running.
9. After each step, summarize what changed, why, and one small exercise for me to learn.
Constraints:
- Do not enable or change any system DND settings without my explicit typed approval.
- Keep code minimal and well-commented.
Output format for each step: 1) files changed, 2) commands to run, 3) how to test, 4) learning notes.
```

---

# Final tips & gotchas

* Android DND requires user-granted access; your app cannot silently flip system DND — open the system settings screen and ask the user to enable it. ([Android Developers][5])
* Linux desktops vary; implement GNOME via `gsettings` and fallback gracefully. Test on your distro. ([jyn.dev][6])
* Supabase + Google requires configuring OAuth credentials and redirect URIs — follow Supabase docs carefully (client ID/secret, scopes). ([Supabase][4])
