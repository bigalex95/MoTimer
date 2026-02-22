## Phase 8 — Build, test & release

What to do

* Test on Android physical device (enable USB debugging) and on Linux desktop (`flutter run -d linux`).
* Build Android APK / appbundle and Linux release binary:
  ```bash
  flutter build apk --release
  flutter build linux --release
  ```
* Polish UI / accessibility / icons.

Why

* Teaches building and packaging for two targets.
