import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps [FlutterLocalNotificationsPlugin] for MoTimer.
///
/// Call [init] once at app startup, then use [showTimerComplete] when a
/// session finishes.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialise the notification plugin for each platform.
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open MoTimer');

    const settings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(settings: settings);

    // On Android 13+ request notification permission.
    await _requestPermissionIfNeeded();

    _initialized = true;
  }

  /// Show a notification when a timer session completes.
  ///
  /// [isFocusComplete] — true when a focus session just ended (break is next),
  /// false when a break ended (focus is next).
  Future<void> showTimerComplete({required bool isFocusComplete}) async {
    if (!_initialized) return;

    final title =
        isFocusComplete ? 'Focus complete!' : 'Break over!';
    final body = isFocusComplete
        ? 'Great work! Time for a break 🎉'
        : 'Let\'s get back to it! 💪';

    const androidDetails = AndroidNotificationDetails(
      'motimer_session',
      'Timer Sessions',
      channelDescription: 'Notifications when a MoTimer session finishes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const linuxDetails = LinuxNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ── Private helpers ──────────────────────────────────

  Future<void> _requestPermissionIfNeeded() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }
}
