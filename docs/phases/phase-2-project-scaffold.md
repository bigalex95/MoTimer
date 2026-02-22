## Phase 2 — Project scaffold & basic packages

What to implement

* Create project and add minimal dependencies:

  ```bash
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
* flutter_local_notifications: [https://pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

Why

* This phase teaches adding packages, dependency management, and the pattern for wiring third-party SDKs into Flutter.
