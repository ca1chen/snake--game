/// 简易 debug 日志工具
class Logger {
  static bool _enabled = true;

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  static void d(String tag, String message) {
    if (_enabled) {
      // ignore: avoid_print
      print('[DEBUG][$tag] $message');
    }
  }

  static void e(String tag, String message, [Object? error]) {
    // ignore: avoid_print
    print('[ERROR][$tag] $message ${error ?? ''}');
  }
}
