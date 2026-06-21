/// 待办优先级
enum Priority {
  low,    // 0
  medium, // 1
  high,   // 2
}

/// 待办任务数据模型
class TodoItem {
  final int? id;
  final String title;
  final String description;
  final Priority priority;
  final String dueDate;       // "yyyy-MM-dd"
  final String? dueTime;      // "HH:mm" or null = 全天
  final bool isCompleted;
  final DateTime? completedAt;
  final int? courseId;        // 关联课程 ID，null = 独立待办
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TodoItem({
    this.id,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    required this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    this.completedAt,
    this.courseId,
    this.createdAt,
    this.updatedAt,
  });

  /// 从数据库 Map 创建（带类型安全 fallback）
  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String? ?? '',
      priority: Priority.values[(map['priority'] as int?) ?? 1],
      dueDate: (map['due_date'] as String?) ?? DateTime.now().toIso8601String().split('T').first,
      dueTime: map['due_time'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'].toString()) : null,
      courseId: map['course_id'] as int?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'due_date': dueDate,
      'due_time': dueTime,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'course_id': courseId,
    };
  }

  /// 是否逾期
  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final due = DateTime.tryParse(dueDate);
    if (due == null) return false;
    if (due.isAfter(now)) return false;
    if (dueTime != null && due.isAtSameMomentAs(now.normalized())) {
      // 同一天，检查时间
      final parts = dueTime!.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return now.hour > hour || (now.hour == hour && now.minute >= minute);
    }
    return due.isBefore(now.normalized());
  }

  TodoItem copyWith({
    int? id,
    String? title,
    String? description,
    Priority? priority,
    String? dueDate,
    String? dueTime,
    bool? isCompleted,
    DateTime? completedAt,
    int? courseId,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      courseId: courseId ?? this.courseId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() => 'TodoItem(id:$id, title:$title, priority:${priority.name}, completed:$isCompleted)';
}

extension _DateTimeNormalize on DateTime {
  DateTime normalized() => DateTime(year, month, day);
}
