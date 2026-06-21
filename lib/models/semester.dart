/// 学期数据模型
class Semester {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int totalWeeks;
  final bool isCurrent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Semester({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.totalWeeks = 18,
    this.isCurrent = false,
    this.createdAt,
    this.updatedAt,
  });

  /// 从数据库 Map 创建（带类型安全 fallback）
  factory Semester.fromMap(Map<String, dynamic> map) {
    final startStr = map['start_date'] as String?;
    final endStr = map['end_date'] as String?;
    return Semester(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      startDate: startStr != null ? (DateTime.tryParse(startStr) ?? DateTime.now()) : DateTime.now(),
      endDate: endStr != null ? (DateTime.tryParse(endStr) ?? DateTime.now()) : DateTime.now(),
      totalWeeks: map['total_weeks'] as int? ?? 18,
      isCurrent: (map['is_current'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'total_weeks': totalWeeks,
      'is_current': isCurrent ? 1 : 0,
    };
  }

  Semester copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    int? totalWeeks,
    bool? isCurrent,
  }) {
    return Semester(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() => 'Semester(id:$id, name:$name, current:$isCurrent, weeks:$totalWeeks)';
}
