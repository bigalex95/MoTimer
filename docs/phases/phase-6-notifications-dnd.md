## Phase 6 — Notifications & Do-Not-Disturb behavior

What to implement

1. Local notifications: use `flutter_local_notifications` to show a notification at timer end (and optionally when started). Read the plugin docs: [https://pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications).
2. Android DND behavior:
   * Android requires the `ACCESS_NOTIFICATION_POLICY` permission to change global DND. The user must grant this in Settings (cannot be silently granted). In your app:
     * Add `android.permission.ACCESS_NOTIFICATION_POLICY` to `AndroidManifest.xml`.
     * Check `NotificationManager.isNotificationPolicyAccessGranted()` and, if not granted, open the settings screen:
       ```java
       startActivity(new Intent(android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS));
       ```
     * If granted, you can call `NotificationManager.setInterruptionFilter(...)` to set zen mode. See Android docs on `NotificationManager` and `setInterruptionFilter`.
3. Linux desktop DND:
   * Many Linux desktops (GNOME) expose a GSettings key for DND. You can toggle `"org.gnome.desktop.notifications" show-banners` with `gsettings`:
     ```bash
     gsettings set org.gnome.desktop.notifications show-banners false
     gsettings set org.gnome.desktop.notifications show-banners true
     ```
     * Run these from Dart via `Process.run()` when the user allows it. Note: different desktop environments behave differently; implement GNOME support and fall back to app-only suppression. See examples: [https://jyn.dev/do-not-disturb-in-gnome/](https://jyn.dev/do-not-disturb-in-gnome/) and askubuntu instructions.

Safety & UX note

* Because toggling global DND changes system behavior, always request explicit consent and show a clear dialog. On Android, open the system settings and ask the user to grant DND access.

Why

* Teaches you platform integration and permission flows. You'll learn how to do small native interactions from Flutter.
