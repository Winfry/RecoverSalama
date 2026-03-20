import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles daily check-in reminders and push notifications.
/// Scheduled notifications remind patients to do their daily check-in.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  /// Schedule daily check-in reminder at 9 AM
  static Future<void> scheduleDailyCheckInReminder() async {
    // TODO: Implement scheduled notification
    // Use flutter_local_notifications zonedSchedule
  }

  /// Show immediate notification (e.g., emergency alert response)
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'salama_recover',
        'SalamaRecover',
        channelDescription: 'Recovery notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(0, title, body, details);
  }
}
