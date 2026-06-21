import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';

/// 数据库实例 Provider（全局单例）
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});
