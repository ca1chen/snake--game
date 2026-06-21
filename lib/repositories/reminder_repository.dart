import '../database/database_constants.dart';
import '../database/database_helper.dart';
import '../models/reminder.dart';

/// 提醒数据仓库
class ReminderRepository {
  final DatabaseHelper _dbHelper;

  ReminderRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// 插入新提醒
  Future<int> insert(Reminder reminder) async {
    final db = await _dbHelper.database;
    return await db.insert(DB.tableReminders, reminder.toMap());
  }

  /// 更新提醒
  Future<int> update(Reminder reminder) async {
    final db = await _dbHelper.database;
    return await db.update(
      DB.tableReminders,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  /// 删除提醒
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DB.tableReminders,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除某待办的所有提醒
  Future<int> deleteByTodoId(int todoId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DB.tableReminders,
      where: 'todo_id = ?',
      whereArgs: [todoId],
    );
  }

  /// 获取某待办的所有提醒
  Future<List<Reminder>> getByTodo(int todoId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DB.tableReminders,
      where: 'todo_id = ?',
      whereArgs: [todoId],
      orderBy: 'remind_minutes DESC',
    );
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  /// 获取所有未触发的提醒
  Future<List<Reminder>> getPendingReminders() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DB.tableReminders,
      where: 'is_triggered = 0',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  /// 标记提醒已触发
  Future<void> markTriggered(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      DB.tableReminders,
      {'is_triggered': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
