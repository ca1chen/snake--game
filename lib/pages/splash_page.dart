import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/semester.dart';
import '../providers/semester_provider.dart';
import '../providers/course_provider.dart';
import '../providers/todo_provider.dart';
import '../services/notification_service.dart';
import '../services/course_import_service.dart';
import '../repositories/semester_repository.dart';
import '../repositories/course_repository.dart';
import '../data/tju_seed_courses.dart';
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
      // 1. 通知服务在后台并行初始化（与其他步骤无关）
      setState(() => _status = AppStrings.splashInitNotify);
      final notifyFuture = NotificationService.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () => {},
      );

      // 2. 加载学期数据（触发数据库初始化，后续步骤依赖它）
      setState(() => _status = AppStrings.splashLoadData);
      await ref.read(semesterProvider.notifier).loadSemesters().timeout(
        const Duration(seconds: 10),
        onTimeout: () => {},
      );

      // 3. 首次启动时导入种子数据
      await seedTJUCoursesIfEmpty().timeout(
        const Duration(seconds: 15),
        onTimeout: () => {},
      );

      // 4. 课程/待办/分享导入 并行加载
      setState(() => _status = AppStrings.splashLoadData);
      await Future.wait([
        ref.read(courseProvider.notifier).loadCourses().timeout(
          const Duration(seconds: 10),
          onTimeout: () => {},
        ),
        ref.read(todoProvider.notifier).loadTodos().timeout(
          const Duration(seconds: 10),
          onTimeout: () => {},
        ),
        _handleSharedImport().timeout(
          const Duration(seconds: 10),
          onTimeout: () => {},
        ),
      ]);

      // 等待通知服务初始化完成
      await notifyFuture;

      setState(() => _ready = true);
    } catch (e) {
      // 即使出错也进入主页
      setState(() => _ready = true);
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
