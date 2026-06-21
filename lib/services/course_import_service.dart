import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import '../models/course.dart';
import '../utils/gbk_decoder.dart';

/// 解析结果
class ImportResult {
  final String semesterName;
  final int courseCount;
  final List<Course> courses;
  final List<String> warnings;

  ImportResult({
    required this.semesterName,
    required this.courseCount,
    required this.courses,
    this.warnings = const [],
  });
}

/// 天大选课网导出的 HTML 伪 Excel 课表解析器
class CourseImportService {
  /// 从文件路径解析课表
  static Future<ImportResult> parseFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return await parseBytes(bytes);
  }

  /// 从字节数组解析课表（用于分享接收场景）
  static Future<ImportResult> parseBytes(List<int> bytes) async {
    await GbkDecoder.ensureInitialized();
    final html = GbkDecoder.decode(bytes);
    return _parseHtml(html);
  }

  /// 解析 HTML 内容
  static ImportResult _parseHtml(String html) {
    final document = html_parser.parse(html);
    final courses = <Course>[];
    final warnings = <String>[];

    // 提取学期名
    final h3 = document.querySelector('h3');
    final semesterName = h3?.text.trim() ?? '导入的课表';

    // 找到课程表
    final table = document.querySelector('#manualArrangeCourseTable');
    if (table == null) {
      return ImportResult(
        semesterName: semesterName,
        courseCount: 0,
        courses: [],
        warnings: ['未找到课表表格，请确认文件格式正确'],
      );
    }

    // 遍历所有课程单元格
    final infoCells = table.querySelectorAll('td.infoTitle');
    if (infoCells.isEmpty) {
      return ImportResult(
        semesterName: semesterName,
        courseCount: 0,
        courses: [],
        warnings: ['未找到课程数据，表格中无 infoTitle 单元格'],
      );
    }

    for (final cell in infoCells) {
      final id = cell.attributes['id'] ?? '';
      final rowspan = int.tryParse(cell.attributes['rowspan'] ?? '2') ?? 2;
      final title = cell.attributes['title'] ?? '';

      if (title.isEmpty) continue;

      // 从 id 提取 day 和 period
      // id 格式: TD{n}_{m}, n = (day-1)*12 + (period-1)
      final idMatch = RegExp(r'TD(\d+)_').firstMatch(id);
      if (idMatch == null) {
        warnings.add('无法解析单元格 ID: $id');
        continue;
      }
      final n = int.parse(idMatch.group(1)!);
      final day = (n ~/ 12) + 1; // 1=周一, 7=周日
      final period = (n % 12) + 1; // 1-12节

      // 解析 title 中的课程信息
      final parsed = _parseTitle(title);
      for (final entry in parsed) {
        try {
          courses.add(Course(
            semesterId: 0, // 由调用方填充
            name: entry.name,
            teacher: entry.teacher,
            classroom: entry.classroom,
            dayOfWeek: day,
            startPeriod: period,
            duration: rowspan,
            startWeek: entry.startWeek,
            endWeek: entry.endWeek,
            weekType: entry.weekType,
            color: _pickColor(courses.length),
            notes: entry.notes,
          ));
        } catch (e) {
          warnings.add('解析失败: $title — $e');
        }
      }
    }

    return ImportResult(
      semesterName: semesterName,
      courseCount: courses.length,
      courses: courses,
      warnings: warnings,
    );
  }

  /// 解析单个单元格的 title 属性
  static List<_CourseEntry> _parseTitle(String title) {
    final entries = <_CourseEntry>[];

    // 分号分割
    final parts = title.split(';').where((p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return entries;

    // 每两个 parts 构成一个课程条目
    for (int i = 0; i < parts.length - 1; i += 2) {
      final namePart = parts[i].trim();
      final schedPart = parts[i + 1].trim();

      // 解析课程名和教师: "课程名 (教师)"（课程名可能含全角括号）
      final nameMatch = RegExp(r'^(.+)\s*\((.+)\)\s*$').firstMatch(namePart);
      if (nameMatch == null) {
        // 尝试跳过 — 可能是格式问题
        continue;
      }
      final courseName = nameMatch.group(1)!.trim();
      final teacher = nameMatch.group(2)!.trim();

      // 解析排课信息: "(单/双?周范围,教室)"
      final sched = _parseSchedule(schedPart);

      entries.add(_CourseEntry(
        name: courseName,
        teacher: teacher,
        classroom: sched.classroom,
        startWeek: sched.startWeek,
        endWeek: sched.endWeek,
        weekType: sched.weekType,
        notes: sched.notes,
      ));
    }

    // 奇数个 parts（最后多余的被忽略，记录警告用）
    return entries;
  }

  /// 解析排课字符串
  static _ScheduleInfo _parseSchedule(String raw) {
    // 去掉外层括号
    var s = raw.trim();
    if (s.startsWith('(')) s = s.substring(1);
    if (s.endsWith(')')) s = s.substring(0, s.length - 1);
    s = s.trim();

    var weekType = WeekType.every;
    var classroom = '';
    var notes = '';

    // 检查单双周标记
    if (s.startsWith('单')) {
      weekType = WeekType.odd;
      s = s.substring(1).trim();
    } else if (s.startsWith('双')) {
      weekType = WeekType.even;
      s = s.substring(1).trim();
    }

    // 去掉末尾 "周"
    if (s.endsWith('周')) {
      s = s.substring(0, s.length - 1).trim();
    }

    // 查找最后一个逗号，其后可能是教室也可能是备注
    final lastComma = s.lastIndexOf(',');
    if (lastComma > 0) {
      classroom = s.substring(lastComma + 1).trim();
      s = s.substring(0, lastComma).trim();
      // 如果"教室"不是正常教室格式（如在线教学），作为备注
      if (classroom.contains('在线') ||
          classroom.contains('网络') ||
          classroom.isEmpty ||
          classroom.length > 20) {
        notes = classroom;
        classroom = '';
      }
    }

    // 解析周次范围
    int startWeek = 1;
    int endWeek = 18;

    // 匹配周次数值段: "1-16", "1-6 8-16", "12" 等
    final weekPattern = RegExp(r'(\d+)(?:-(\d+))?');
    final matches = weekPattern.allMatches(s);
    final weekSegments = <_WeekRange>[];

    for (final m in matches) {
      final start = int.parse(m.group(1)!);
      final end = m.group(2) != null ? int.parse(m.group(2)!) : start;
      weekSegments.add(_WeekRange(start, end));
    }

    if (weekSegments.isNotEmpty) {
      startWeek = weekSegments.map((w) => w.start).reduce((a, b) => a < b ? a : b);
      endWeek = weekSegments.map((w) => w.end).reduce((a, b) => a > b ? a : b);

      // 检查是否有不连续周次（如 1-6 和 8-16，中间跳过7）
      if (weekSegments.length > 1) {
        for (int i = 0; i < weekSegments.length - 1; i++) {
          if (weekSegments[i].end + 1 < weekSegments[i + 1].start) {
            notes = '${notes}第${weekSegments[i].end + 1}-${weekSegments[i + 1].start - 1}周除外;'.trim();
          }
        }
      }
    }

    return _ScheduleInfo(
      startWeek: startWeek,
      endWeek: endWeek,
      weekType: weekType,
      classroom: classroom,
      notes: notes,
    );
  }

  /// 课程颜色轮换
  static final List<String> _colorPalette = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FFEAA7', '#DDA0DD', '#F7DC6F', '#BB8FCE',
    '#85C1E9', '#82E0AA', '#F8C471', '#D7BDE2',
    '#A3E4D7', '#AED6F1', '#98D8C8', '#F1948A',
  ];

  static String _pickColor(int index) {
    return _colorPalette[index % _colorPalette.length];
  }
}

// --- 内部辅助类型 ---

class _CourseEntry {
  final String name;
  final String teacher;
  final String classroom;
  final int startWeek;
  final int endWeek;
  final WeekType weekType;
  final String notes;

  _CourseEntry({
    required this.name,
    required this.teacher,
    this.classroom = '',
    this.startWeek = 1,
    this.endWeek = 18,
    this.weekType = WeekType.every,
    this.notes = '',
  });
}

class _ScheduleInfo {
  final int startWeek;
  final int endWeek;
  final WeekType weekType;
  final String classroom;
  final String notes;

  _ScheduleInfo({
    this.startWeek = 1,
    this.endWeek = 18,
    this.weekType = WeekType.every,
    this.classroom = '',
    this.notes = '',
  });
}

class _WeekRange {
  final int start;
  final int end;
  _WeekRange(this.start, this.end);
}
