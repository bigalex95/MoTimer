# MoTimer

MoTimer is a minimal, offline-first focus timer built with Flutter. It aims to offer a Pomodoro-style experience with customizable duration and UI themes, integrated with your system's notifications and Do Not Disturb settings.

## Features
- **Core Timer**: Pomodoro-style presets and custom duration settings.
- **Custom UI**: Configurable theme colors and minimal design.
- **Notifications**: End-of-session system notifications.
- **Do Not Disturb**: Optional DND mode integration while the timer is running.
- **Offline First**: Works without internet access.
- **Optional Account Sync**: (Optional) Sign in with Google to use Supabase to sync your settings across devices.

---

## Installation Guide

### Prerequisites
Before you begin, ensure you have the [Flutter SDK installed](https://docs.flutter.dev/get-started/install) on your development machine.

---

### Installing on Android
You can run MoTimer immediately on your phone through USB debugging, or you can build an APK and install it manually.

#### 1. Direct Install (ADB/USB Debugging)
If your Android phone is connected to your computer via USB and has **Developer Mode** & **USB Debugging** enabled:
```bash
# Verify your device is detected
flutter devices

# Run the app directly on your phone
flutter run -d android --release
```

#### 2. Building an APK to Install Later
To create an APK file that you can share or install on an Android device manually without a computer connection:
```bash
# Build the release APK
flutter build apk --release
```
The resulting APK will be saved at:
`/home/bigalex95/Projects/Pet_Projects/MoTimer/build/app/outputs/flutter-apk/app-release.apk`

Transfer this file to your phone (via USB, email, Google Drive, etc.), tap on it within a file manager on your phone, and follow the system prompts to install it. (You may need to allow installing apps from "Unknown Sources" in your device's settings).

---

### Installing on Linux
You can build MoTimer for Linux and run the resulting native executable directly or copy it into your system directories.

#### 1. Direct Run
```bash
# Run the app directly from your terminal
flutter run -d linux --release
```

#### 2. Building a Release Package
To compile a standalone native package that does not require the Flutter SDK to be run:
```bash
# Build the native Linux application
flutter build linux --release
```
The compiled bundle will be located at:
`/home/bigalex95/Projects/Pet_Projects/MoTimer/build/linux/x64/release/bundle/`

**Installing system-wide (Optional):**
To use MoTimer like a standard Linux application with an app launcher icon:
1. Copy the built bundle to a location accessible to user binaries:
```bash
sudo cp -r build/linux/x64/release/bundle /opt/motimer
```

2. Note: A custom .desktop file needs to be created to show up in your application menu, such as `~/.local/share/applications/motimer.desktop`:
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=MoTimer
Exec=/opt/motimer/mo_timer
Icon=/opt/motimer/data/flutter_assets/assets/icon.png
Terminal=false
Categories=Utility;
```
(Adjust the `Icon` path to where you placed your launcher icons if you separated them).

---

## License
MIT
