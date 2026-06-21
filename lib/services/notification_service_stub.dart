/// Stub — 仅用于分析器，运行时不会被加载。
class NotificationService {
  static Future<void> init() =>
      throw UnsupportedError('Platform not supported');
  static Future<int?> scheduleTodoReminder({
    required int id,
    required String todoTitle,
    required String dueDate,
    String? dueTime,
    int remindMinutes = 30,
  }) =>
      throw UnsupportedError('Platform not supported');
  static Future<void> cancelNotification(int id) =>
      throw UnsupportedError('Platform not supported');
}
