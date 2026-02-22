import 'dart:io' show Platform, Process;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform-abstracted Do-Not-Disturb service.
///
/// * **Android** — uses a MethodChannel to native Kotlin code that calls
///   `NotificationManager.setInterruptionFilter()`.
/// * **Linux (GNOME)** — toggles `org.gnome.desktop.notifications show-banners`
///   via `gsettings`.
/// * **Other platforms** — no-op.
class DndService {
  DndService._();
  static final DndService instance = DndService._();

  static const _channel = MethodChannel('com.motimer/dnd');

  // ── Public API ───────────────────────────────────────

  /// Whether the current platform supports DND toggling at all.
  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isLinux;
  }

  /// Check whether the app already has DND / notification-policy access.
  ///
  /// On Linux this is always true (no special permission needed).
  Future<bool> hasAccess() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      try {
        final granted = await _channel.invokeMethod<bool>('checkDndAccess');
        return granted ?? false;
      } catch (e) {
        debugPrint('DND checkAccess error: $e');
        return false;
      }
    }
    if (Platform.isLinux) return true;
    return false;
  }

  /// Open the system settings page where the user can grant DND access.
  ///
  /// Only relevant on Android.
  Future<void> requestAccess() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestDndAccess');
      } catch (e) {
        debugPrint('DND requestAccess error: $e');
      }
    }
  }

  /// Enable or disable Do-Not-Disturb mode.
  Future<void> setDnd(bool enabled) async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('setDnd', {'enabled': enabled});
      } catch (e) {
        debugPrint('DND setDnd error: $e');
      }
    } else if (Platform.isLinux) {
      await _setGnomeDnd(enabled);
    }
  }

  // ── Linux / GNOME helpers ────────────────────────────

  Future<void> _setGnomeDnd(bool enabled) async {
    try {
      // show-banners = false → DND on (suppress notifications)
      // show-banners = true  → DND off (normal)
      final value = enabled ? 'false' : 'true';
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.notifications',
        'show-banners',
        value,
      ]);
    } catch (e) {
      debugPrint('GNOME DND toggle failed: $e');
    }
  }
}
