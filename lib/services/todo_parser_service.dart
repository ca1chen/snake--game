import '../models/parsed_todo.dart';
import '../models/todo_item.dart';

/// 语音文本智能解析器
/// 将自然语言文本解析为结构化待办数据
/// 纯规则引擎，无需外部 API，完全离线可用
class TodoParserService {
  /// 解析原始语音文本，返回待办列表
  /// 返回空列表表示未检测到有效任务
  static List<ParsedTodo> parse(String rawText) {
    if (rawText.trim().isEmpty) return [];

    // 1. 分割段落
    final segments = _splitSegments(rawText);
    if (segments.isEmpty) return [];

    // 2. 逐段解析
    final results = <ParsedTodo>[];
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i].trim();
      if (segment.isEmpty) continue;

      String remaining = segment;

      // 2a. 提取优先级
      final priorityResult = _extractPriority(remaining);
      final priority = priorityResult.priority;
      remaining = priorityResult.remaining;

      // 2b. 提取日期
      final dateResult = _extractDate(remaining);
      final dueDate = dateResult.date;
      remaining = dateResult.remaining;

      // 2c. 提取时间
      final timeResult = _extractTime(remaining);
      final dueTime = timeResult.time;
      remaining = timeResult.remaining;

      // 2d. 清理标题
      final title = _cleanTitle(remaining);

      if (title.isEmpty) continue;

      results.add(ParsedTodo(
        index: i,
        title: title,
        priority: priority,
        dueDate: dueDate,
        dueTime: dueTime,
        rawText: segment,
      ));
    }

    return results;
  }

  // --- 1. 分割 ---

  static final RegExp _splitPattern = RegExp(
    r'[；;。！!\n]|然后|还有|另外|接着|下一步|接下来|以及|再者|还有还有|其次',
  );

  static List<String> _splitSegments(String text) {
    // 先用标点分割
    final parts = text.split(_splitPattern);
    return parts.where((p) => p.trim().isNotEmpty).toList();
  }

  // --- 2a. 优先级提取 ---

  static final List<_PriorityRule> _priorityRules = [
    _PriorityRule(RegExp(r'(很紧急|特别紧急|非常紧急|特急|紧急|马上|立刻|立即|尽快|火速|赶紧)'), Priority.high),
    _PriorityRule(RegExp(r'(中等|中级|重要|优先|着重|必做)'), Priority.medium),
    _PriorityRule(RegExp(r'(不着急|不急|普通|一般|低优|随意|无所谓|不急迫|不急办)'), Priority.low),
  ];

  static _PriorityResult _extractPriority(String text) {
    for (final rule in _priorityRules) {
      final match = rule.pattern.firstMatch(text);
      if (match != null) {
        // 移除匹配的关键词及其后可能的标点
        final cleaned = text.replaceRange(match.start, match.end, '').trim();
        return _PriorityResult(rule.priority, cleaned);
      }
    }
    return _PriorityResult(Priority.medium, text);
  }

  // --- 2b. 日期提取 ---

  /// 日期提取结果
  static _DateResult _extractDate(String text) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 尝试各种日期模式（按优先级）

    // 模式 A：相对日
    final relative = _matchRelativeDay(text, today);
    if (relative != null) return relative;

    // 模式 B：周X
    final weekday = _matchWeekday(text, today);
    if (weekday != null) return weekday;

    // 模式 C：M月D日
    final monthDay = _matchMonthDay(text, today);
    if (monthDay != null) return monthDay;

    // 模式 D：D号
    final dayOnly = _matchDayOnly(text, today);
    if (dayOnly != null) return dayOnly;

    // 无日期匹配 → 默认今天
    return _DateResult(_formatDate(today), text);
  }

  /// 今天/明天/后天/大后天
  static _DateResult? _matchRelativeDay(String text, DateTime today) {
    final patterns = [
      (RegExp(r'今天'), 0),
      (RegExp(r'明天|明日'), 1),
      (RegExp(r'后天|后日'), 2),
      (RegExp(r'大后天'), 3),
    ];

    for (final (pattern, offset) in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final date = today.add(Duration(days: offset));
        final cleaned = text.replaceRange(match.start, match.end, '').trim();
        return _DateResult(_formatDate(date), cleaned);
      }
    }
    return null;
  }

  /// 下周X / 这周X / 周X
  static _DateResult? _matchWeekday(String text, DateTime today) {
    final pattern = RegExp(r'(下周|下个星期|下星期|这周|这个星期|这星期|本周)?周([一二三四五六日天])');
    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final prefix = match.group(1) ?? '';
    final dayChar = match.group(2)!;

    const dayMap = <String, int>{
      '一': 1, '二': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '日': 7, '天': 7,
    };
    final targetDay = dayMap[dayChar]!;
    final todayDay = today.weekday;

    DateTime date;
    if (prefix.contains('下')) {
      // 下周X
      final daysUntil = (targetDay - todayDay + 7) % 7;
      date = today.add(Duration(days: daysUntil == 0 ? 7 : daysUntil + 7));
    } else if (prefix.contains('这') || prefix.contains('本')) {
      // 这周X
      final daysUntil = (targetDay - todayDay + 7) % 7;
      date = today.add(Duration(days: daysUntil));
    } else {
      // 裸"周X" — 默认本周（已过则下周）
      final daysUntil = (targetDay - todayDay + 7) % 7;
      final candidate = today.add(Duration(days: daysUntil));
      if (candidate.isBefore(today) || candidate == today) {
        date = candidate.add(const Duration(days: 7));
      } else {
        date = candidate;
      }
    }

    final cleaned = text.replaceRange(match.start, match.end, '').trim();
    return _DateResult(_formatDate(date), cleaned);
  }

  /// M月D日
  static _DateResult? _matchMonthDay(String text, DateTime today) {
    final pattern = RegExp(r'(\d{1,2})月(\d{1,2})[日号]');
    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    DateTime date;
    try {
      date = DateTime(today.year, month, day);
    } catch (_) {
      return null;
    }

    final cleaned = text.replaceRange(match.start, match.end, '').trim();
    return _DateResult(_formatDate(date), cleaned);
  }

  /// D号（推断当月或下月）
  static _DateResult? _matchDayOnly(String text, DateTime today) {
    final pattern = RegExp(r'(下个月|下月)?(\d{1,2})[日号]');
    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final nextMonth = match.group(1) != null;
    final day = int.parse(match.group(2)!);
    if (day < 1 || day > 31) return null;

    DateTime date;
    if (nextMonth) {
      // 下月X号
      final next = DateTime(today.year, today.month + 1, 1);
      try {
        date = DateTime(next.year, next.month, day);
      } catch (_) {
        return null;
      }
    } else {
      // 当月X号（已过则下月）
      try {
        final candidate = DateTime(today.year, today.month, day);
        date = candidate.isBefore(today) && !_isSameDay(candidate, today)
            ? DateTime(today.year, today.month + 1, day)
            : candidate;
      } catch (_) {
        return null;
      }
    }

    final cleaned = text.replaceRange(match.start, match.end, '').trim();
    return _DateResult(_formatDate(date), cleaned);
  }

  // --- 2c. 时间提取 ---

  static _TimeResult _extractTime(String text) {
    // 模式 1："下午3点半"、"上午9点20分"、"晚上8点"
    final cnPattern1 = RegExp(
      r'(上午|下午|中午|晚上|早上|傍晚|凌晨|午)?(\d{1,2})点(半|(\d{1,2})分?)?',
    );

    final match1 = cnPattern1.firstMatch(text);
    if (match1 != null) {
      final modifier = match1.group(1) ?? '';
      int hour = int.parse(match1.group(2)!);
      final half = match1.group(3) == '半';
      final minuteStr = match1.group(4);
      int minute = 0;

      if (half) {
        minute = 30;
      } else if (minuteStr != null) {
        minute = int.parse(minuteStr);
      }

      // 根据修饰词调整小时
      if (modifier.contains('下') || modifier.contains('晚') || modifier.contains('傍晚')) {
        if (hour < 12) hour += 12; // 下午/晚上：1→13, 8→20
        if (hour == 12 && modifier.contains('晚')) hour = 0; // 晚上12点 = 00:00
      } else if (modifier.contains('上') || modifier.contains('早') || modifier.contains('凌晨')) {
        if (hour == 12) hour = 0; // 上午12点 → 0点
      } else if (modifier.contains('中') || modifier.contains('午')) {
        if (hour < 12) hour += 12; // 中午1点 = 13点
      }
      // 无修饰词且 hour < 8 → 可能是下午
      else if (modifier.isEmpty && hour < 8) {
        hour += 12;
      }

      if (hour > 23) hour = 23;
      if (minute > 59) minute = 59;

      final cleaned = text.replaceRange(match1.start, match1.end, '').trim();
      return _TimeResult(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        cleaned,
      );
    }

    // 模式 2："15:30"、"9:00"
    final colonPattern = RegExp(r'(\d{1,2}):(\d{2})');
    final match2 = colonPattern.firstMatch(text);
    if (match2 != null) {
      final hour = int.parse(match2.group(1)!).clamp(0, 23);
      final minute = int.parse(match2.group(2)!).clamp(0, 59);
      final cleaned = text.replaceRange(match2.start, match2.end, '').trim();
      return _TimeResult(
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        cleaned,
      );
    }

    return _TimeResult(null, text);
  }

  // --- 2d. 标题清理 ---

  static String _cleanTitle(String text) {
    return text
        // 去除首尾标点和空白
        .replaceAll(RegExp(r'^[,，。.、\s]+|[,，。.、\s]+$'), '')
        // 去除噪声词
        .replaceAll(RegExp(r'^(一下|一个|帮我|请|麻烦|帮忙|给我|帮我在?)[,，]?\s*'), '')
        // 去除动词前缀
        .replaceAll(RegExp(r'^(做|完成|写|复习|预习|看|背|提交|交|整理|去|要|记得|别忘了?)[，,]?\s*'), '')
        .trim();
  }

  // --- 辅助 ---

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// --- 内部辅助类型 ---

class _PriorityRule {
  final RegExp pattern;
  final Priority priority;
  _PriorityRule(this.pattern, this.priority);
}

class _PriorityResult {
  final Priority priority;
  final String remaining;
  _PriorityResult(this.priority, this.remaining);
}

class _DateResult {
  final String date; // yyyy-MM-dd
  final String remaining;
  _DateResult(this.date, this.remaining);
}

class _TimeResult {
  final String? time; // HH:mm 或 null
  final String remaining;
  _TimeResult(this.time, this.remaining);
}
