import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/semester.dart';
import '../models/course.dart';
import '../providers/semester_provider.dart';
import '../providers/course_provider.dart';
import '../providers/todo_provider.dart';
import '../services/notification_service.dart';
import '../services/course_import_service.dart';
import '../repositories/semester_repository.dart';
import '../repositories/course_repository.dart';
import '../utils/app_strings.dart';
import '../main.dart' show pendingImportPath;

/// 启动页 — 初始化数据库和通知服务
class SplashPage extends ConsumerStatefulWidget {
  final Widget? child;

  const SplashPage({super.key, this.child});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _ready = false;
  String _status = AppStrings.splashInit;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. 初始化通知服务
      setState(() => _status = AppStrings.splashInitNotify);
      await NotificationService.init();

      // 2. 加载学期数据（触发数据库初始化）
      setState(() => _status = AppStrings.splashLoadData);
      await ref.read(semesterProvider.notifier).loadSemesters();

      // 3. 首次启动时，导入课表种子数据
      await _seedIfEmpty();

      // 4. 加载课程和待办
      await ref.read(courseProvider.notifier).loadCourses();
      await ref.read(todoProvider.notifier).loadTodos();

      // 5. 处理系统分享导入
      await _handleSharedImport();

      setState(() => _ready = true);
    } catch (e) {
      // 即使出错也进入主页
      setState(() => _ready = true);
    }
  }

  /// 首次启动时导入课表数据
  Future<void> _seedIfEmpty() async {
    final semRepo = SemesterRepository();
    final courseRepo = CourseRepository();

    final existingSemesters = await semRepo.getAll();
    if (existingSemesters.isNotEmpty) return; // 已有数据，跳过

    setState(() => _status = AppStrings.splashSeedData);

    // 创建学期（使用天大校历开学日期）
    const semesterName = '2025-2026学年第二学期';
    final startDate = CourseImportService.estimateSemesterStart(semesterName);
    final semester = Semester(
      name: semesterName,
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 18 * 7 - 1)),
      totalWeeks: 18,
      isCurrent: true,
    );
    final semesterId = await semRepo.insert(semester);

    // 课程数据
    final courses = <Course>[
      // 周一 1-2节
      Course(semesterId: semesterId, name: '微积分II', teacher: '尚英锋', classroom: '45楼B307', dayOfWeek: 1, startPeriod: 1, duration: 2, startWeek: 1, endWeek: 14, weekType: WeekType.every, color: '#FF6B6B'),
      Course(semesterId: semesterId, name: '中国近现代史纲要', teacher: '黎博雅', classroom: '45楼B211', dayOfWeek: 1, startPeriod: 3, duration: 2, startWeek: 1, endWeek: 15, weekType: WeekType.odd, color: '#96CEB4'),
      Course(semesterId: semesterId, name: '大学物理2A', teacher: '肖立峰', classroom: '33楼204', dayOfWeek: 1, startPeriod: 5, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#45B7D1'),
      Course(semesterId: semesterId, name: '理论力学3', teacher: '钟顺', classroom: '37楼511', dayOfWeek: 1, startPeriod: 7, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#F7DC6F'),
      // 周二 1-2节
      Course(semesterId: semesterId, name: '工程图学3A', teacher: '景秀并', classroom: '33楼109', dayOfWeek: 2, startPeriod: 1, duration: 2, startWeek: 4, endWeek: 15, weekType: WeekType.every, color: '#4ECDC4'),
      // 周二 3-4节
      Course(semesterId: semesterId, name: '工程图学3A', teacher: '景秀并', classroom: '33楼109', dayOfWeek: 2, startPeriod: 3, duration: 2, startWeek: 4, endWeek: 15, weekType: WeekType.every, color: '#4ECDC4'),
      // 周二 5-6节
      Course(semesterId: semesterId, name: '翻译与跨文化传播', teacher: '张宇', classroom: '46楼A107', dayOfWeek: 2, startPeriod: 5, duration: 2, startWeek: 1, endWeek: 15, weekType: WeekType.odd, color: '#98D8C8'),
      // 周二 7-8节
      Course(semesterId: semesterId, name: '英语交流与沟通', teacher: '张文真', classroom: '46楼A209', dayOfWeek: 2, startPeriod: 7, duration: 2, startWeek: 2, endWeek: 16, weekType: WeekType.even, color: '#85C1E9'),
      // 周二 9-10节 (前8周)
      Course(semesterId: semesterId, name: '职业生涯规划', teacher: '艾丽皮热·衣沙克', classroom: '45楼B115', dayOfWeek: 2, startPeriod: 9, duration: 2, startWeek: 1, endWeek: 8, weekType: WeekType.every, color: '#A3E4D7'),
      // 周二 9-10节 (后8周)
      Course(semesterId: semesterId, name: '大学生心理健康（下）', teacher: '刘新春', classroom: '45楼B115', dayOfWeek: 2, startPeriod: 9, duration: 2, startWeek: 9, endWeek: 16, weekType: WeekType.every, color: '#AED6F1'),
      // 周三 1-2节
      Course(semesterId: semesterId, name: '微积分II', teacher: '尚英锋', classroom: '45楼B307', dayOfWeek: 3, startPeriod: 1, duration: 2, startWeek: 1, endWeek: 14, weekType: WeekType.every, color: '#FF6B6B'),
      // 周三 3-4节
      Course(semesterId: semesterId, name: '中国近现代史纲要', teacher: '黎博雅', classroom: '45楼B211', dayOfWeek: 3, startPeriod: 3, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#96CEB4'),
      // 周三 5-6节
      Course(semesterId: semesterId, name: '理论力学3', teacher: '钟顺', classroom: '37楼511', dayOfWeek: 3, startPeriod: 5, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#F7DC6F'),
      // 周三 7-8节
      Course(semesterId: semesterId, name: '线性代数初步', teacher: '张颖', classroom: '45楼B109', dayOfWeek: 3, startPeriod: 7, duration: 2, startWeek: 1, endWeek: 12, weekType: WeekType.every, color: '#DDA0DD'),
      // 周三 9-10节
      Course(semesterId: semesterId, name: '大学化学1', teacher: '马亚鲁', classroom: '46楼A205', dayOfWeek: 3, startPeriod: 9, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#82E0AA'),
      // 周四 1-2节
      Course(semesterId: semesterId, name: '大学物理2A', teacher: '肖立峰', classroom: '33楼204', dayOfWeek: 4, startPeriod: 1, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#45B7D1'),
      // 周四 3-4节
      Course(semesterId: semesterId, name: '体育B', teacher: '杨玉明', classroom: '', dayOfWeek: 4, startPeriod: 3, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#FFEAA7'),
      // 周四 7-8节
      Course(semesterId: semesterId, name: '工程图学3A', teacher: '景秀并', classroom: '33楼109', dayOfWeek: 4, startPeriod: 7, duration: 2, startWeek: 4, endWeek: 15, weekType: WeekType.every, color: '#4ECDC4'),
      // 周四 9-10节
      Course(semesterId: semesterId, name: '学科前沿导论与认知实习', teacher: '刘海涛', classroom: '46楼A110', dayOfWeek: 4, startPeriod: 9, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#F8C471'),
      // 周五 1-2节
      Course(semesterId: semesterId, name: '微积分II', teacher: '尚英锋', classroom: '45楼B307', dayOfWeek: 5, startPeriod: 1, duration: 2, startWeek: 1, endWeek: 14, weekType: WeekType.every, color: '#FF6B6B'),
      // 周五 3-4节
      Course(semesterId: semesterId, name: '线性代数初步', teacher: '张颖', classroom: '45楼B109', dayOfWeek: 5, startPeriod: 3, duration: 2, startWeek: 1, endWeek: 12, weekType: WeekType.every, color: '#DDA0DD'),
      // 周五 5-6节
      Course(semesterId: semesterId, name: '国家安全教育', teacher: '王茜', classroom: '45楼B201', dayOfWeek: 5, startPeriod: 5, duration: 2, startWeek: 1, endWeek: 4, weekType: WeekType.every, color: '#BB8FCE'),
      // 周五 9-10节
      Course(semesterId: semesterId, name: '军事理论1', teacher: '朱丙锋', classroom: '33楼113', dayOfWeek: 5, startPeriod: 9, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#D7BDE2', notes: '第7周在线教学'),
      // 周日 3-4节 (工程图学实验)
      Course(semesterId: semesterId, name: '工程图学3A', teacher: '景秀并', classroom: '33楼108', dayOfWeek: 7, startPeriod: 3, duration: 2, startWeek: 12, endWeek: 12, weekType: WeekType.every, color: '#4ECDC4'),
    ];

    for (final course in courses) {
      await courseRepo.insert(course);
    }
  }

  /// 处理系统分享导入的文件
  Future<void> _handleSharedImport() async {
    if (pendingImportPath == null) return;

    setState(() => _status = AppStrings.splashImportShared);

    try {
      final importResult = await CourseImportService.parseFile(pendingImportPath!);
      pendingImportPath = null; // 清除，避免重复导入

      if (importResult.courses.isEmpty) return;

      // 查找或创建学期
      final semRepo = SemesterRepository();
      final courseRepo = CourseRepository();
      final semesters = await semRepo.getAll();

      Semester? semester;
      for (final s in semesters) {
        if (s.name == importResult.semesterName) {
          semester = s;
          break;
        }
      }
      int semesterId;
      if (semester != null) {
        semesterId = semester.id!;
      } else {
        final startDate = CourseImportService.estimateSemesterStart(importResult.semesterName);
        final newSem = Semester(
          name: importResult.semesterName,
          startDate: startDate,
          endDate: startDate.add(const Duration(days: 18 * 7 - 1)),
          totalWeeks: 18,
          isCurrent: semesters.isEmpty,
        );
        semesterId = await semRepo.insert(newSem);
      }

      for (final course in importResult.courses) {
        final c = course.copyWith(semesterId: semesterId);
        await courseRepo.insert(c);
      }

      await ref.read(courseProvider.notifier).loadCourses();
      await ref.read(semesterProvider.notifier).loadSemesters();
    } catch (e) {
      // 静默处理错误，不阻塞启动
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready && widget.child != null) {
      return widget.child!;
    }

    if (_ready) {
      // fallback: 没有 child 直接显示空白（不会发生）
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'FirstCC',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(AppStrings.appSubtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text(_status, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
