## Phase 1 — Dev environment (Linux + Android)

What to do (commands + links)

1. Install Flutter SDK and desktop prerequisites on Linux (Ubuntu example):

   * Follow official docs: [https://docs.flutter.dev/platform-integration/linux/setup](https://docs.flutter.dev/platform-integration/linux/setup) and [https://docs.flutter.dev/install](https://docs.flutter.dev/install).

     ```bash
     sudo apt update
     sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
     # download flutter sdk, extract, add to PATH per docs
     ```

2. Android setup (Android SDK / platform-tools / emulator or device): follow Flutter Android setup: [https://docs.flutter.dev/platform-integration/android/setup](https://docs.flutter.dev/platform-integration/android/setup). Then run:

   ```bash
   flutter doctor
   flutter devices
   ```

   Install Android Studio or SDK tools as instructed.

Why

* `flutter doctor` will teach you how Flutter diagnoses missing pieces. This phase gets your environment ready to run both Linux desktop and Android builds.

---

### Execution Results (flutter doctor)

```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.38.5, on Ubuntu 22.04.5 LTS 6.8.0-100-generic, locale en_US.UTF-8)
[✓] Android toolchain - develop for Android devices (Android SDK version 36.1.0)
[✓] Chrome - develop for the web
[✓] Linux toolchain - develop for Linux desktop
[✓] Connected device (2 available)
[✓] Network resources

• No issues found!
```
