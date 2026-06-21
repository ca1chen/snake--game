import 'package:intl/intl.dart';

/// 日期工具类 — 学期周次计算、日期格式化
class DateUtils {
  /// 计算某个日期在学期中的周次（从1开始）
  /// [semesterStart] 学期第一天（开学日）
  /// [date] 目标日期
  /// 返回: 周次（1-based），不在学期内返回 -1
  static int getWeekNumber(DateTime semesterStart, DateTime date) {
    final diff = date.difference(semesterStart.normalized()).inDays;
    if (diff < 0) return -1;
    return (diff / 7).floor() + 1;
  }

  /// 计算学期某周的周一日期
  static DateTime getWeekStartDate(DateTime semesterStart, int weekNumber) {
    return semesterStart.normalized().add(Duration(days: (weekNumber - 1) * 7));
  }

  /// 获取某天是星期几（1=周一, 7=周日）
  static int getDayOfWeek(DateTime date) {
    // DateTime.weekday: 1=Monday, 7=Sunday
    return date.weekday;
  }

  /// 格式化日期为 yyyy-MM-dd
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 格式化日期为中文显示 "10月15日 周一"
  static String formatDateCN(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final month = date.month;
    final day = date.day;
    final weekday = weekdays[date.weekday - 1];
    return '$month月${day}日 $weekday';
  }

  /// 解析 ISO 日期字符串
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// 获取今天的日期字符串
  static String today() => formatDate(DateTime.now());

  /// 判断两个日期是否是同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 计算两个日期相差的天数（忽略时间分量）
  static int daysBetween(DateTime a, DateTime b) {
    return a.normalized().difference(b.normalized()).inDays.abs();
  }
}

extension _DateNormalize on DateTime {
  /// 归一化到当天 00:00:00
  DateTime normalized() => DateTime(year, month, day);
}
