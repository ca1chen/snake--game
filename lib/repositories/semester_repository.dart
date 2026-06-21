import '../database/database_constants.dart';
import '../database/database_helper.dart';
import '../models/semester.dart';

/// 学期数据仓库
class SemesterRepository {
  final DatabaseHelper _dbHelper;

  SemesterRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// 插入新学期
  Future<int> insert(Semester semester) async {
    final db = await _dbHelper.database;
    return await db.insert(DB.tableSemesters, semester.toMap());
  }

  /// 更新学期
  Future<int> update(Semester semester) async {
    final db = await _dbHelper.database;
    return await db.update(
      DB.tableSemesters,
      semester.toMap(),
      where: 'id = ?',
      whereArgs: [semester.id],
    );
  }

  /// 删除学期
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DB.tableSemesters,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有学期（按开始日期排序）
  Future<List<Semester>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DB.tableSemesters,
      orderBy: 'start_date DESC',
    );
    return maps.map((m) => Semester.fromMap(m)).toList();
  }

  /// 根据 ID 获取学期
  Future<Semester?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DB.tableSemesters,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Semester.fromMap(maps.first);
  }

  /// 获取当前学期
  Future<Semester?> getCurrent() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DB.tableSemesters,
      where: 'is_current = 1',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Semester.fromMap(maps.first);
  }

  /// 设置为当前学期（先取消所有，再设置目标）
  Future<void> setCurrent(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      DB.tableSemesters,
      {'is_current': 0},
    );
    await db.update(
      DB.tableSemesters,
      {'is_current': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
