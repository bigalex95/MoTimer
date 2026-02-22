# Final tips & gotchas

* Android DND requires user-granted access; your app cannot silently flip system DND — open the system settings screen and ask the user to enable it.
* Linux desktops vary; implement GNOME via `gsettings` and fallback gracefully. Test on your distro.
* Supabase + Google (optional sync) requires configuring OAuth credentials and redirect URIs — follow Supabase docs carefully if you enable this feature.

# Useful links compilation

* Flutter install / Linux setup: [https://docs.flutter.dev/platform-integration/linux/setup](https://docs.flutter.dev/platform-integration/linux/setup)
* Flutter Android setup: [https://docs.flutter.dev/platform-integration/android/setup](https://docs.flutter.dev/platform-integration/android/setup)
* Supabase Google login (optional): [https://supabase.com/docs/guides/auth/social-login/auth-google](https://supabase.com/docs/guides/auth/social-login/auth-google)
* flutter_local_notifications: [https://pub.dev/packages/flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
* GNOME DND (gsettings): [https://jyn.dev/do-not-disturb-in-gnome/](https://jyn.dev/do-not-disturb-in-gnome/)
* AskUbuntu toggle DND CLI example: [https://askubuntu.com/questions/1267256/is-there-a-way-to-toggle-do-not-disturb-from-the-commandline](https://askubuntu.com/questions/1267256/is-there-a-way-to-toggle-do-not-disturb-from-the-commandline)
