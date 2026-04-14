import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Handles daily check-in reminders and push notifications.
/// Scheduled notifications remind patients to do their daily check-in.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone data — required for zonedSchedule
    tz_data.initializeTimeZones();

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

  /// Schedule a daily check-in reminder at 9 AM device local time.
  ///
  /// Uses zonedSchedule so the notification fires at 9 AM regardless
  /// of what timezone the device is in. Repeats daily automatically.
  /// Safe to call multiple times — cancels any existing reminder first.
  static Future<void> scheduleDailyCheckInReminder() async {
    // Cancel any existing reminder before scheduling a new one
    await _plugin.cancel(1);

    const androidDetails = AndroidNotificationDetails(
      'salama_recover_daily',
      'Daily Check-In Reminder',
      channelDescription: 'Reminds you to do your daily recovery check-in',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for 9 AM today (or tomorrow if 9 AM has already passed)
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9, // 9 AM
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1, // notification ID
      'SalamaRecover — Daily Check-In',
      'Time for your recovery check-in. How are you feeling today?',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  /// Cancel the daily reminder (e.g., when patient disables notifications)
  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(1);
  }

  /// Show an immediate notification (e.g., after a HIGH risk check-in)
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
