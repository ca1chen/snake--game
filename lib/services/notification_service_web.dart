import 'dart:async';
import 'dart:html' as html;
import '../utils/logger.dart';

/// 通知服务（Web 端：Browser Notification API + Timer）
class NotificationService {
  static bool _initialized = false;
  static bool _permissionGranted = false;
  static final Map<int, Timer> _activeTimers = {};

  static Future<void> init() async {
    if (_initialized) return;

    try {
      if (html.Notification.supported) {
        final perm = await html.Notification.requestPermission();
        _permissionGranted = perm == 'granted';
        Logger.d('Notification', 'Web permission: $_permissionGranted');
      } else {
        Logger.d('Notification', 'Browser Notification not supported');
      }
    } catch (e) {
      Logger.d('Notification', 'Web init error: $e');
    }
    _initialized = true;
  }

  static Future<int?> scheduleTodoReminder({
    required int id,
    required String todoTitle,
    required String dueDate,
    String? dueTime,
    int remindMinutes = 30,
  }) async {
    if (!_initialized) await init();
    if (!_permissionGranted) return null;

    final dueDateTime = _parseDueDateTime(dueDate, dueTime);
    if (dueDateTime == null) return null;

    final scheduledTime =
        dueDateTime.subtract(Duration(minutes: remindMinutes));
    if (scheduledTime.isBefore(DateTime.now())) return null;

    final delay = scheduledTime.difference(DateTime.now());
    final notifId = id + 10000;

    _activeTimers[notifId]?.cancel();
    _activeTimers[notifId] = Timer(delay, () {
      _showNotification(notifId, '⏰ 任务提醒', todoTitle);
      _activeTimers.remove(notifId);
    });

    Logger.d('Notification',
        'Scheduled web reminder for "$todoTitle" in ${delay.inMinutes} min');
    return notifId;
  }

  static void _showNotification(int id, String title, String body) {
    try {
      if (html.Notification.supported && _permissionGranted) {
        html.Notification(title,
            body: body,
            tag: id.toString(),
            icon: 'icons/Icon-192.png');
      }
    } catch (e) {
      Logger.d('Notification', 'Show error: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    final notifId = id + 10000;
    _activeTimers[notifId]?.cancel();
    _activeTimers.remove(notifId);
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
}
