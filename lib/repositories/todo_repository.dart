import '../database/database_constants.dart';
import '../database/database_helper.dart';
import '../models/todo_item.dart';

/// 待办数据仓库
class TodoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 插入新待办
  Future<int> insert(TodoItem todo) async {
    final db = await _dbHelper.database;
    return await db.insert(DB.tableTodos, todo.toMap());
  }

  /// 更新待办
  Future<int> update(TodoItem todo) async {
    final db = await _dbHelper.database;
    return await db.update(
      DB.tableTodos,
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// 删除待办
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DB.tableTodos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 根据 ID 获取待办
  Future<TodoItem?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DB.tableTodos,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TodoItem.fromMap(maps.first);
  }

  /// 获取所有待办（按截止日期+优先级排序）
  Future<List<TodoItem>> getAll({bool? isCompleted}) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;

    if (isCompleted != null) {
      where = 'is_completed = ?';
      whereArgs = [isCompleted ? 1 : 0];
    }

    final maps = await db.query(
      DB.tableTodos,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'is_completed ASC, due_date ASC, priority DESC',
    );
    return maps.map((m) => TodoItem.fromMap(m)).toList();
  }

  /// 获取某门课程的待办
  Future<List<TodoItem>> getByCourse(int courseId, {bool? isCompleted}) async {
    final db = await _dbHelper.database;
    String where = 'course_id = ?';
    List<dynamic> whereArgs = [courseId];

    if (isCompleted != null) {
      where += ' AND is_completed = ?';
      whereArgs.add(isCompleted ? 1 : 0);
    }

    final maps = await db.query(
      DB.tableTodos,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'is_completed ASC, due_date ASC, priority DESC',
    );
    return maps.map((m) => TodoItem.fromMap(m)).toList();
  }

  /// 获取某日期的待办
  Future<List<TodoItem>> getByDate(String date, {bool? isCompleted}) async {
    final db = await _dbHelper.database;
    String where = 'due_date = ?';
    List<dynamic> whereArgs = [date];

    if (isCompleted != null) {
      where += ' AND is_completed = ?';
      whereArgs.add(isCompleted ? 1 : 0);
    }

    final maps = await db.query(
      DB.tableTodos,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'priority DESC, due_time ASC',
    );
    return maps.map((m) => TodoItem.fromMap(m)).toList();
  }

  /// 获取未完成待办数量（按课程统计）
  Future<int> getIncompleteCountByCourse(int courseId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${DB.tableTodos} WHERE course_id = ? AND is_completed = 0',
      [courseId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// 切换待办完成状态
  Future<void> toggleComplete(int id) async {
    final todo = await getById(id);
    if (todo == null) return;
    final db = await _dbHelper.database;
    await db.update(
      DB.tableTodos,
      {
        'is_completed': todo.isCompleted ? 0 : 1,
        'completed_at': todo.isCompleted ? null : DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取逾期未完成任务
  Future<List<TodoItem>> getOverdueIncomplete() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final db = await _dbHelper.database;
    final maps = await db.query(
      DB.tableTodos,
      where: 'is_completed = 0 AND due_date < ?',
      whereArgs: [today],
      orderBy: 'due_date ASC, priority DESC',
    );
    return maps.map((m) => TodoItem.fromMap(m)).toList();
  }
}
