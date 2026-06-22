import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';

/// SQLite 数据库单例（移动端：sqflite）
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;
  static Future<Database>? _initFuture;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // 防止并发初始化：多个调用方共享同一个 Future
    _initFuture ??= _initDatabase();
    _database = await _initFuture;
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

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      _initFuture = null;
      Logger.d('DB', 'Database closed');
    }
  }

  Future<void> reset() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    await deleteDatabase(path);
    _initFuture = _initDatabase();
    _database = await _initFuture;
    Logger.d('DB', 'Database reset');
  }
}
