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
