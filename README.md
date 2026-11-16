# MoTimer

A minimal, offline-first focus timer (Pomodoro style) built with Flutter. Settings can optionally be synced across devices through Supabase with Google sign-in.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build](https://github.com/bigalex95/MoTimer/actions/workflows/build.yml/badge.svg)](https://github.com/bigalex95/MoTimer/actions/workflows/build.yml)

<!-- TODO: screenshots (home timer, settings screen) -->

## Features

- Focus/break timer with two built-in presets (Pomodoro 25/5, Long Focus 50/10) and adjustable focus and break durations.
- Theme color options.
- End-of-session local notification, with optional sound and vibration.
- Optional Do Not Disturb while the timer runs. Supported on Android (needs notification-policy access, requested in-app) and on Linux/GNOME (toggles `show-banners`). Not available on other platforms.
- Works fully offline; settings are stored locally with `shared_preferences`.
- Optional account sync: sign in with Google through Supabase to sync settings (durations, theme, sound, vibration, DND) between devices. Sync happens on app start and from a manual sync button.

## Architecture

- UI: `lib/home_screen.dart`, `lib/settings_screen.dart`, `lib/auth_screen.dart`.
- Services (`lib/services`): `TimerService` (state machine), `SettingsService` (local storage and Supabase sync), `NotificationService`, `DndService`.
- Sync: one Supabase table `settings (user_id, key, value, updated_at)` with Row Level Security; per-key timestamps decide which side wins. Supabase is only initialized once the user has opted in.

## Getting started

Prerequisite: Flutter SDK (Dart `^3.10.4`).

```bash
flutter pub get
flutter test                      # TimerService unit tests (10 tests)
flutter run -d linux              # or: -d android
flutter build apk --release       # build/app/outputs/flutter-apk/app-release.apk
flutter build linux --release     # build/linux/x64/release/bundle/
```

The Linux bundle can be copied to `/opt/motimer` and launched via a `.desktop` entry (`Exec=/opt/motimer/mo_timer`). CI (`.github/workflows/build.yml`) builds the Android APK and the Linux bundle on pushes and pull requests to `main`/`master`.

## Configuration (optional sync)

The timer works without any configuration. The sync feature talks to a Supabase project whose URL and anon key are set in `lib/env.dart`:

```dart
class Env {
  static const supabaseUrl = '...';
  static const supabaseAnonKey = '...';
}
```

The anon key is a public client key. It ships inside every client build by design and grants no more than what the database policies allow. Access control comes from Row Level Security: the `settings` table has a policy so that users can only read and write rows where `auth.uid() = user_id`. Never put a `service_role` key in the client.

To use your own Supabase project:

1. Create a project at supabase.com.
2. In the SQL editor, run [`docs/supabase_settings_table.sql`](docs/supabase_settings_table.sql). It creates the `settings` table and enables RLS with the per-user policy.
3. Enable the Google provider under Authentication and create OAuth credentials in Google Cloud Console (see the Supabase Google auth guide). Add `com.motimer://login-callback` to the redirect URLs for Android sign-in.
4. Replace `supabaseUrl` and `supabaseAnonKey` in `lib/env.dart` with your project's values (Project Settings, API).
5. Rebuild the app.

## Project structure

```
lib/
  main.dart, home_screen.dart, settings_screen.dart, auth_screen.dart, env.dart
  models/preset.dart
  services/   timer, settings (+sync), notification, dnd
test/widget_test.dart            TimerService unit tests
docs/
  supabase_settings_table.sql    sync table + RLS policy
  phases/                        original build plan, one file per phase
  master-promt.md                original project brief
android/ linux/ ios/ macos/ windows/ web/
```

## Status and limitations

- Version 1.0.0, personal project. CI and the documented build targets are Android and Linux; other platform folders are Flutter defaults and untested.
- Supabase URL and anon key are compile-time constants in `lib/env.dart`; moving them to `--dart-define` is a possible improvement.
- The Android application id is still the template `com.example.mo_timer`.
- Tests cover `TimerService` only.

## License

MIT, see [LICENSE](LICENSE).
