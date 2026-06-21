import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../utils/logger.dart';

/// 本地通知服务
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// 初始化通知（在 main.dart 中调用）
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

    // 创建 Android 通知渠道
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

  /// 定时提醒
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

    // 如果提醒时间已过，不调度
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

      Logger.d('Notification', 'Scheduled reminder for "$todoTitle" at $scheduledTime');
      return notifId;
    } catch (e) {
      Logger.e('Notification', 'Failed to schedule reminder', e);
      return null;
    }
  }

  /// 取消通知
  static Future<void> cancelNotification(int id) async {
    final notifId = id + 10000;
    await _plugin.cancel(notifId);
  }

  /// 解析到期时间
  static DateTime? _parseDueDateTime(String dueDate, String? dueTime) {
    final date = DateTime.tryParse(dueDate);
    if (date == null) return null;

    if (dueTime != null && dueTime.contains(':')) {
      final parts = dueTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    // 全天任务，默认 08:00 到期
    return DateTime(date.year, date.month, date.day, 8, 0);
  }

  /// 通知点击回调
  static void _onNotificationTap(NotificationResponse response) {
    Logger.d('Notification', 'Tapped notification: ${response.payload}');
    // TODO: 根据 payload 导航到对应待办详情页
    // 可通过全局 navigator key 实现
  }
}
