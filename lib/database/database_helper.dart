import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';

/// SQLite 数据库单例
class DatabaseHelper {
  static late final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    Logger.d('DB', 'Opening database at $path');

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // 启用外键约束
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    Logger.d('DB', 'Creating tables (version $version)...');
    for (final sql in DB.allCreateTables) {
      await db.execute(sql);
    }
    Logger.d('DB', 'All tables created successfully');
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      Logger.d('DB', 'Database closed');
    }
  }

  /// 重置数据库（删除并重建）
  Future<void> reset() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    await deleteDatabase(path);
    _database = await _initDatabase();
    Logger.d('DB', 'Database reset');
  }
}
