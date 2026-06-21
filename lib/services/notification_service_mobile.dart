import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../utils/logger.dart';

/// 本地通知服务（移动端：flutter_local_notifications）
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const androidChannel = AndroidNotificationChannel(
      'course_reminder',
      '课程提醒',
      description: '上课、作业截止、考试提醒',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    Logger.d('Notification', 'Initialized');
  }

  static Future<int?> scheduleTodoReminder({
    required int id,
    required String todoTitle,
    required String dueDate,
    String? dueTime,
    int remindMinutes = 30,
  }) async {
    if (!_initialized) await init();

    final dueDateTime = _parseDueDateTime(dueDate, dueTime);
    if (dueDateTime == null) return null;

    final scheduledTime = dueDateTime.subtract(Duration(minutes: remindMinutes));
    if (scheduledTime.isBefore(DateTime.now())) {
      Logger.d('Notification', 'Reminder time already passed for "$todoTitle"');
      return null;
    }

    try {
      final notifId = id + 10000;

      await _plugin.zonedSchedule(
        notifId,
        '⏰ 任务提醒',
        todoTitle,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'course_reminder',
            '任务提醒',
            channelDescription: '待办任务截止提醒',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      Logger.d('Notification',
          'Scheduled reminder for "$todoTitle" at $scheduledTime');
      return notifId;
    } catch (e) {
      Logger.e('Notification', 'Failed to schedule reminder', e);
      return null;
    }
  }

  static Future<void> cancelNotification(int id) async {
    final notifId = id + 10000;
    await _plugin.cancel(notifId);
  }

  static DateTime? _parseDueDateTime(String dueDate, String? dueTime) {
    final date = DateTime.tryParse(dueDate);
    if (date == null) return null;

    if (dueTime != null && dueTime.contains(':')) {
      final parts = dueTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    return DateTime(date.year, date.month, date.day, 8, 0);
  }

  static void _onNotificationTap(NotificationResponse response) {
    Logger.d('Notification', 'Tapped notification: ${response.payload}');
  }
}
