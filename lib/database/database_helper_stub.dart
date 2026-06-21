/// Stub — 仅用于分析器，运行时不会被加载。
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._();

  Future<dynamic> get database =>
      throw UnsupportedError('Platform not supported');
  Future<void> close() async {}
  Future<void> reset() async {}
}
