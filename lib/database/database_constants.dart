/// 数据库表名与列名常量
class DB {
  // 表名
  static const String tableSemesters = 'semesters';
  static const String tableCourses = 'courses';
  static const String tableTodos = 'todos';
  static const String tableReminders = 'reminders';

  // semesters 表 SQL
  static const String createSemestersTable = '''
    CREATE TABLE IF NOT EXISTS $tableSemesters (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      name          TEXT    NOT NULL,
      start_date    TEXT    NOT NULL,
      end_date      TEXT    NOT NULL,
      total_weeks   INTEGER NOT NULL DEFAULT 18,
      is_current    INTEGER NOT NULL DEFAULT 0,
      created_at    TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      updated_at    TEXT    NOT NULL DEFAULT (datetime('now','localtime'))
    );
  ''';

  // courses 表 SQL
  static const String createCoursesTable = '''
    CREATE TABLE IF NOT EXISTS $tableCourses (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      semester_id   INTEGER NOT NULL,
      name          TEXT    NOT NULL,
      teacher       TEXT    NOT NULL DEFAULT '',
      classroom     TEXT    NOT NULL DEFAULT '',
      day_of_week   INTEGER NOT NULL CHECK(day_of_week BETWEEN 1 AND 7),
      start_period  INTEGER NOT NULL CHECK(start_period BETWEEN 1 AND 12),
      duration      INTEGER NOT NULL DEFAULT 2,
      start_week    INTEGER NOT NULL DEFAULT 1,
      end_week      INTEGER NOT NULL DEFAULT 18,
      week_type     INTEGER NOT NULL DEFAULT 0,
      color         TEXT    NOT NULL DEFAULT '#4A90D9',
      notes         TEXT    NOT NULL DEFAULT '',
      created_at    TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      updated_at    TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      FOREIGN KEY (semester_id) REFERENCES $tableSemesters(id) ON DELETE CASCADE
    );
  ''';

  // todos 表 SQL
  static const String createTodosTable = '''
    CREATE TABLE IF NOT EXISTS $tableTodos (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      title         TEXT    NOT NULL,
      description   TEXT    NOT NULL DEFAULT '',
      priority      INTEGER NOT NULL DEFAULT 0,
      due_date      TEXT    NOT NULL,
      due_time      TEXT,
      is_completed  INTEGER NOT NULL DEFAULT 0,
      completed_at  TEXT,
      course_id     INTEGER,
      created_at    TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      updated_at    TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      FOREIGN KEY (course_id) REFERENCES $tableCourses(id) ON DELETE SET NULL
    );
  ''';

  // reminders 表 SQL
  static const String createRemindersTable = '''
    CREATE TABLE IF NOT EXISTS $tableReminders (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      todo_id         INTEGER NOT NULL,
      remind_minutes  INTEGER NOT NULL DEFAULT 30,
      is_triggered    INTEGER NOT NULL DEFAULT 0,
      notification_id INTEGER,
      created_at      TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      FOREIGN KEY (todo_id) REFERENCES $tableTodos(id) ON DELETE CASCADE
    );
  ''';

  /// 所有建表语句
  static const List<String> allCreateTables = [
    createSemestersTable,
    createCoursesTable,
    createTodosTable,
    createRemindersTable,
  ];
}
