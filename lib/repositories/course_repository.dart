import '../database/database_constants.dart';
import '../database/database_helper.dart';
import '../models/course.dart';

/// 课程数据仓库
class CourseRepository {
  final DatabaseHelper _dbHelper;

  CourseRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// 插入新课程
  Future<int> insert(Course course) async {
    final db = await _dbHelper.database;
    return await db.insert(DB.tableCourses, course.toMap());
  }

  /// 更新课程
  Future<int> update(Course course) async {
    final db = await _dbHelper.database;
    return await db.update(
      DB.tableCourses,
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  /// 删除课程
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DB.tableCourses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取某学期的所有课程
  Future<List<Course>> getBySemester(int semesterId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DB.tableCourses,
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      orderBy: 'day_of_week, start_period',
    );
    return maps.map((m) => Course.fromMap(m)).toList();
  }

  /// 根据 ID 获取课程
  Future<Course?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DB.tableCourses,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  /// 获取某学期、某天、某周的所有课程
  /// 返回活跃课程（在周次范围内且匹配单双周）
  Future<List<Course>> getActiveForDay(int semesterId, int dayOfWeek, int weekNumber) async {
    final allCourses = await getBySemester(semesterId);
    return allCourses.where((c) => c.isActiveAt(dayOfWeek, weekNumber)).toList();
  }

  /// 获取某学期某周的所有活跃课程
  Future<Map<int, List<Course>>> getActiveForWeek(int semesterId, int weekNumber) async {
    final allCourses = await getBySemester(semesterId);
    final Map<int, List<Course>> result = {};
    for (int day = 1; day <= 7; day++) {
      result[day] = allCourses.where((c) => c.isActiveAt(day, weekNumber)).toList();
    }
    return result;
  }

  /// 检测课程时间冲突
  /// 返回与给定时间重叠的课程列表
  Future<List<Course>> checkConflict({
    required int semesterId,
    required int dayOfWeek,
    required int startPeriod,
    required int duration,
    int? excludeCourseId,
  }) async {
    final db = await _dbHelper.database;
    final endPeriod = startPeriod + duration - 1;

    // 查询同一天有重叠时间段的课程
    String where = '''
      semester_id = ?
      AND day_of_week = ?
      AND NOT (start_period + duration - 1 < ? OR start_period > ?)
    ''';
    List<dynamic> whereArgs = [semesterId, dayOfWeek, startPeriod, endPeriod];

    if (excludeCourseId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeCourseId);
    }

    final maps = await db.query(
      DB.tableCourses,
      where: where,
      whereArgs: whereArgs,
    );
    return maps.map((m) => Course.fromMap(m)).toList();
  }
}
