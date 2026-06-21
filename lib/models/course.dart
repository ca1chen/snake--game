/// 上课周类型
enum WeekType {
  every, // 0 - 每周
  odd,   // 1 - 单周
  even,  // 2 - 双周
}

/// 课程数据模型
class Course {
  final int? id;
  final int semesterId;
  final String name;
  final String teacher;
  final String classroom;
  final int dayOfWeek;       // 1=周一, 7=周日
  final int startPeriod;     // 起始节数 1-12
  final int duration;        // 持续节数 1/2/3
  final int startWeek;       // 起始周次
  final int endWeek;         // 结束周次
  final WeekType weekType;   // 每周/单周/双周
  final String color;        // hex 颜色
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Course({
    this.id,
    required this.semesterId,
    required this.name,
    this.teacher = '',
    this.classroom = '',
    required this.dayOfWeek,
    required this.startPeriod,
    this.duration = 2,
    this.startWeek = 1,
    this.endWeek = 18,
    this.weekType = WeekType.every,
    this.color = '#4A90D9',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  /// 从数据库 Map 创建
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int?,
      semesterId: map['semester_id'] as int,
      name: map['name'] as String,
      teacher: map['teacher'] as String? ?? '',
      classroom: map['classroom'] as String? ?? '',
      dayOfWeek: map['day_of_week'] as int,
      startPeriod: map['start_period'] as int,
      duration: map['duration'] as int? ?? 2,
      startWeek: map['start_week'] as int? ?? 1,
      endWeek: map['end_week'] as int? ?? 18,
      weekType: WeekType.values[map['week_type'] as int? ?? 0],
      color: map['color'] as String? ?? '#4A90D9',
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'semester_id': semesterId,
      'name': name,
      'teacher': teacher,
      'classroom': classroom,
      'day_of_week': dayOfWeek,
      'start_period': startPeriod,
      'duration': duration,
      'start_week': startWeek,
      'end_week': endWeek,
      'week_type': weekType.index,
      'color': color,
      'notes': notes,
    };
  }

  /// 判断课程在某周是否上课
  bool isActiveInWeek(int weekNumber) {
    if (weekNumber < startWeek || weekNumber > endWeek) return false;
    switch (weekType) {
      case WeekType.every:
        return true;
      case WeekType.odd:
        return weekNumber % 2 == 1;
      case WeekType.even:
        return weekNumber % 2 == 0;
    }
  }

  /// 判断课程在指定星期几、指定周次是否上课
  bool isActiveAt(int dayOfWeek, int weekNumber) {
    return this.dayOfWeek == dayOfWeek && isActiveInWeek(weekNumber);
  }

  Course copyWith({
    int? id,
    int? semesterId,
    String? name,
    String? teacher,
    String? classroom,
    int? dayOfWeek,
    int? startPeriod,
    int? duration,
    int? startWeek,
    int? endWeek,
    WeekType? weekType,
    String? color,
    String? notes,
  }) {
    return Course(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startPeriod: startPeriod ?? this.startPeriod,
      duration: duration ?? this.duration,
      startWeek: startWeek ?? this.startWeek,
      endWeek: endWeek ?? this.endWeek,
      weekType: weekType ?? this.weekType,
      color: color ?? this.color,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'Course(id:$id, name:$name, day:$dayOfWeek, period:$startPeriod, weeks:$startWeek-$endWeek)';
}
