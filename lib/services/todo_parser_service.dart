import 'package:intl/intl.dart';
import '../models/todo_item.dart';
import '../models/parsed_todo.dart';

/// 纯规则引擎：语音文本 → 待办事项列表
class TodoParserService {
  static const _weekDayMap = {
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '天': 7, '日': 7,
  };

  // ---- 中文数字处理 ----

  /// 将常见中文数字字符串转换为 int，失败返回 null
  /// 支持：零～十、十五、二十、二十五、三十等（最大到九十九）
  static int? _parseChineseNumber(String cn) {
    const single = {
      '零': 0, '一': 1, '二': 2, '两': 2,
      '三': 3, '四': 4, '五': 5,
      '六': 6, '七': 7, '八': 8, '九': 9,
    };
    if (cn.isEmpty) return null;
    if (single.containsKey(cn)) return single[cn]!;

    if (cn == '十') return 10;
    if (cn.startsWith('十')) {
      // 十一～十九
      final ones = single[cn.substring(1)];
      return ones != null ? 10 + ones : null;
    }
    if (cn.endsWith('十')) {
      // 二十、三十...
      final tens = single[cn.substring(0, 1)];
      return tens != null ? tens * 10 : null;
    }
    // 二十一、三十五 … 两位数
    if (cn.length == 2) {
      final tens = single[cn[0]];
      final ones = single[cn[1]];
      if (tens != null && ones != null) return tens * 10 + ones;
    }
    return null;
  }

  /// 从文本中提取第一个数字（支持阿拉伯和中文），返回数字和剩余文本
  /// 只处理简单的 1-2 位数字（日期/时间中够用）
  static (int? number, String remaining) _extractNumber(String text) {
    final arabic = RegExp(r'^(\d{1,2})').firstMatch(text);
    if (arabic != null) {
      return (int.parse(arabic.group(1)!), text.substring(arabic.end));
    }
    final chinese = RegExp(r'^([零一二三四五六七八九十]{1,2})').firstMatch(text);
    if (chinese != null) {
      final val = _parseChineseNumber(chinese.group(1)!);
      return (val, text.substring(chinese.end));
    }
    return (null, text);
  }

  // ---- 主解析 ----

  static List<ParsedTodo> parse(String rawText) {
    if (rawText.trim().isEmpty) return [];
    final segments = _splitSegments(rawText);
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    String? previousDate; // 上一个有效日期，初始为空

    final result = <ParsedTodo>[];
    for (var i = 0; i < segments.length; i++) {
      var text = segments[i].trim();
      if (text.isEmpty) continue;
      final raw = text;

      final priority = _extractPriority(text);
      text = _removePriority(text);

      final dateResult = _extractDate(text, today);
      text = dateResult.remaining;
      String dueDate;

      if (dateResult.date != null) {
        dueDate = dateResult.date!;
        previousDate = dueDate; // 更新为当前新日期
      } else {
        // 没有日期 → 继承上一个有效日期，若无则使用今天
        if (previousDate != null) {
          dueDate = previousDate;
        } else {
          dueDate = todayStr;
          previousDate = todayStr; // 把今天也视为一个有效日期，方便后续继承
        }
      }

      final timeResult = _extractTime(text);
      text = timeResult.remaining;
      final dueTime = timeResult.time;

      text = _cleanTitle(text);
      if (text.isEmpty) text = raw;

      result.add(ParsedTodo(
        index: i,
        title: text,
        priority: priority,
        dueDate: dueDate,
        dueTime: dueTime,
        rawText: raw,
      ));
    }
    return result;
  }

  // ---- 分割 ----

  /// 按中英文标点、连接词分割为多个待办候选
  static List<String> _splitSegments(String text) {
    // 将常见的分隔符号统一替换为标记
    final parts = text
        .replaceAll(RegExp(r'[；;。！!，,？?\n、]+'), '|SPLIT|')
        .split('|SPLIT|');
    final result = <String>[];
    for (final part in parts) {
      // 进一步按连接词分割
      final sub = part
          .replaceAll(RegExp(r'(然后|还有|另外|接着|下一步|其次|再者)'), '|SPLIT|')
          .split('|SPLIT|');
      result.addAll(sub);
    }
    return result.where((s) => s.trim().isNotEmpty).toList();
  }

  // ---- 优先级 ----

  static Priority _extractPriority(String text) {
    if (RegExp(r'紧急|马上|立刻|立即|尽快|火速|赶快').hasMatch(text)) return Priority.high;
    if (RegExp(r'普通|一般|不急|低优|不着急').hasMatch(text)) return Priority.low;
    if (RegExp(r'重要|优先').hasMatch(text)) return Priority.medium;
    return Priority.medium;
  }

  static String _removePriority(String text) =>
      text.replaceAll(RegExp(r'紧急|马上|立刻|立即|尽快|火速|赶快|普通|一般|不急|低优|不着急|重要|优先'), '');

  // ---- 日期提取（已修正下周 bug，并增加合法性校验） ----

  static _ParseResult _extractDate(String text, DateTime today) {
    // 相对日期：今天/明天/后天/大后天
    final relativeMatch = RegExp(r'(今天|明天|后天|大后天)').firstMatch(text);
    if (relativeMatch != null) {
      final offset = {
        '今天': 0, '明天': 1, '后天': 2, '大后天': 3
      }[relativeMatch.group(1)]!;
      return _ParseResult(
        date: DateFormat('yyyy-MM-dd').format(today.add(Duration(days: offset))),
        remaining: text.replaceFirst(relativeMatch.group(1)!, ''),
      );
    }
    // 下周X
    final nextWeek = RegExp(r'下周([一二三四五六日天])').firstMatch(text);
    if (nextWeek != null) {
      final targetDay = _weekDayMap[nextWeek.group(1)]!;
      final diff = (targetDay - today.weekday + 7) % 7;
      final daysToAdd = diff == 0 ? 7 : diff; // 修正：去掉多余的+7
      return _ParseResult(
        date: DateFormat('yyyy-MM-dd').format(today.add(Duration(days: daysToAdd))),
        remaining: text.replaceFirst(nextWeek.group(0)!, ''),
      );
    }
    // 周X（本周）
    final thisWeek = RegExp(r'周([一二三四五六日天])').firstMatch(text);
    if (thisWeek != null) {
      final targetDay = _weekDayMap[thisWeek.group(1)]!;
      final diff = (targetDay - today.weekday + 7) % 7;
      return _ParseResult(
        date: DateFormat('yyyy-MM-dd').format(today.add(Duration(days: diff))),
        remaining: text.replaceFirst(thisWeek.group(0)!, ''),
      );
    }
    // M月D日/D号（支持中文数字）
    final mdMatch = RegExp(
        r'(\d{1,2}|[零一二三四五六七八九十]{1,2})月(\d{1,2}|[零一二三四五六七八九十]{1,2})[日号]')
        .firstMatch(text);
    if (mdMatch != null) {
      final mStr = mdMatch.group(1)!;
      final dStr = mdMatch.group(2)!;
      final m = int.tryParse(mStr) ?? _parseChineseNumber(mStr);
      final d = int.tryParse(dStr) ?? _parseChineseNumber(dStr);
      if (m != null && d != null && _isValidDate(today.year, m, d)) {
        return _ParseResult(
          date: DateFormat('yyyy-MM-dd').format(DateTime(today.year, m, d)),
          remaining: text.replaceFirst(mdMatch.group(0)!, ''),
        );
      }
    }
    // D号/日（当月，允许顺延到下月，支持中文数字）
    final dMatch = RegExp(r'(\d{1,2}|[零一二三四五六七八九十]{1,2})[号日]').firstMatch(text);
    if (dMatch != null) {
      final dStr = dMatch.group(1)!;
      final d = int.tryParse(dStr) ?? _parseChineseNumber(dStr);
      if (d != null) {
        DateTime date;
        if (_isValidDate(today.year, today.month, d)) {
          date = DateTime(today.year, today.month, d);
        } else if (_isValidDate(today.year, today.month + 1, d)) {
          date = DateTime(today.year, today.month + 1, d);
        } else {
          return _ParseResult(date: null, remaining: text);
        }
        return _ParseResult(
          date: DateFormat('yyyy-MM-dd').format(date),
          remaining: text.replaceFirst(dMatch.group(0)!, ''),
        );
      }
    }
    return _ParseResult(date: null, remaining: text);
  }

  static bool _isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1) return false;
    try {
      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day;
    } catch (_) {
      return false;
    }
  }

  // ---- 时间提取（支持中文数字） ----

  static _ParseResult _extractTime(String text) {
    // 匹配模式：可选的时段（上午/下午/晚上），然后数字（阿拉伯或中文），再点/时，可选的分钟
    final tm = RegExp(
      r'(上午|下午|晚上)?'
      r'(\d{1,2}|[零一二三四五六七八九十]{1,2})'
      r'[点时]'
      r'(半|(\d{1,2}|[零一二三四五六七八九十]{1,2})分?)?'
    ).firstMatch(text);

    if (tm != null) {
      final period = tm.group(1) ?? '';
      final hourStr = tm.group(2)!;
      final minutePart = tm.group(3); // "半" 或 数字
      final minuteNumStr = tm.group(4); // 数字

      var hour = int.tryParse(hourStr) ?? _parseChineseNumber(hourStr);
      if (hour == null) {
        // 无法解析小时，跳过
        return _ParseResult(time: null, remaining: text);
      }

      int minute = 0;
      if (minutePart == '半') {
        minute = 30;
      } else if (minuteNumStr != null) {
        minute = int.tryParse(minuteNumStr) ?? _parseChineseNumber(minuteNumStr) ?? 0;
      }

      // 时段调整
      if (period == '下午' && hour < 12) hour += 12;
      if (period == '晚上' && hour < 12) hour += 12;
      if (period == '上午' && hour == 12) hour = 0;

      // 基本合法性
      if (hour > 23 || minute > 59) {
        return _ParseResult(time: null, remaining: text);
      }

      return _ParseResult(
        time: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        remaining: text.replaceFirst(tm.group(0)!, ''),
      );
    }

    // HH:MM 格式（阿拉伯数字）
    final hhmm = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (hhmm != null) {
      final h = int.parse(hhmm.group(1)!);
      final m = int.parse(hhmm.group(2)!);
      if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return _ParseResult(
          time: '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
          remaining: text.replaceFirst(hhmm.group(0)!, ''),
        );
      }
    }

    return _ParseResult(time: null, remaining: text);
  }

  // ---- 标题清理 ----

  static String _cleanTitle(String text) {
    text = text
        .replaceAll(RegExp(r'[；;。！!，,？?]+'), ' ')
        .replaceAll(RegExp(r'一下|一个|帮我|请|麻烦|帮忙|替我'), '')
        .trim();
    return text.replaceAll(RegExp(r'^[，,。!！？?\s]+|[，,。!！？?\s]+$'), '');
  }
}

class _ParseResult {
  final String? date;
  final String? time;
  final String remaining;
  const _ParseResult({this.date, this.time, required this.remaining});
}
