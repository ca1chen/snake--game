/// 提醒数据模型
class Reminder {
  final int? id;
  final int todoId;
  final int remindMinutes;   // 提前多少分钟提醒
  final bool isTriggered;
  final int? notificationId; // flutter_local_notifications 返回的 id
  final DateTime? createdAt;

  Reminder({
    this.id,
    required this.todoId,
    this.remindMinutes = 30,
    this.isTriggered = false,
    this.notificationId,
    this.createdAt,
  });

  /// 从数据库 Map 创建
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      todoId: map['todo_id'] as int,
      remindMinutes: map['remind_minutes'] as int? ?? 30,
      isTriggered: (map['is_triggered'] as int?) == 1,
      notificationId: map['notification_id'] as int?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'todo_id': todoId,
      'remind_minutes': remindMinutes,
      'is_triggered': isTriggered ? 1 : 0,
      'notification_id': notificationId,
    };
  }

  /// 预设提醒选项（分钟）
  static const List<int> presetOptions = [5, 15, 30, 60, 1440]; // 5分钟, 15分钟, 30分钟, 1小时, 1天

  static String formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes 分钟前';
    if (minutes < 1440) return '${minutes ~/ 60} 小时前';
    return '${minutes ~/ 1440} 天前';
  }

  Reminder copyWith({
    int? id,
    int? todoId,
    int? remindMinutes,
    bool? isTriggered,
    int? notificationId,
  }) {
    return Reminder(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      remindMinutes: remindMinutes ?? this.remindMinutes,
      isTriggered: isTriggered ?? this.isTriggered,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'Reminder(id:$id, todoId:$todoId, minutes:$remindMinutes, triggered:$isTriggered)';
}
