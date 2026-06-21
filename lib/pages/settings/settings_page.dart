import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/theme_provider.dart';
import '../../providers/semester_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/semester.dart';
import '../../utils/app_strings.dart';
import '../../models/course.dart';
import '../../repositories/semester_repository.dart';
import '../../repositories/course_repository.dart';
import '../../services/course_import_service.dart';
import '../../router/app_router.dart' show AppRouter, rootNavigatorKey;

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final semesterState = ref.watch(semesterProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 学期管理入口
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text(AppStrings.semesterManagement),
            subtitle: Text(semesterState.currentSemester?.name ?? AppStrings.settingsNotSetSemester),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppRouter.goSemesters(context),
          ),
        ),

        // 课程管理入口
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text(AppStrings.courseManagement),
            subtitle: Text('${semesterState.currentSemester != null ? AppStrings.courseManageAll : AppStrings.schedulePleaseSetSemester}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: semesterState.currentSemester != null
                ? () => AppRouter.goCourseList(context)
                : null,
          ),
        ),

        // 导入课表入口
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text(AppStrings.settingsImport),
            subtitle: const Text(AppStrings.settingsImportDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _handleImport(context, ref),
          ),
        ),

        const SizedBox(height: 16),

        // 主题设置
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('主题模式', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('浅色'), icon: Icon(Icons.light_mode, size: 18)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('深色'), icon: Icon(Icons.dark_mode, size: 18)),
                    ButtonSegment(value: ThemeMode.system, label: Text('系统'), icon: Icon(Icons.settings_brightness, size: 18)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) => ref.read(themeProvider.notifier).setTheme(s.first),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 关于
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text(AppStrings.settingsAbout),
                subtitle: const Text(AppStrings.settingsVersion),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text(AppStrings.settingsDescription),
                subtitle: const Text('轻量化 · 无广告 · 极简高效'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 处理课表导入
  static Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    // 使用 root navigator 做所有 dialog 操作，避免 context 在异步后过期
    final nav = rootNavigatorKey.currentState;
    final navCtx = rootNavigatorKey.currentContext ?? context;

    try {
      // 1. 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final fileBytes = file.bytes;
      final filePath = file.path;

      if (fileBytes == null && filePath == null) return;

      // 2. 解析课表
      _showLoading(navCtx, '正在解析课表...');
      final importResult = fileBytes != null
          ? await CourseImportService.parseBytes(fileBytes)
          : await CourseImportService.parseFile(filePath!);
      nav?.pop(); // dismiss loading

      if (importResult.courses.isEmpty) {
        _showError(navCtx, '未解析到任何课程', importResult.warnings.join('\n'));
        return;
      }

      // 3. 确认导入
      final confirmed = await _showConfirmDialog(
        navCtx,
        importResult.semesterName,
        importResult.courseCount,
        importResult.warnings,
      );
      if (confirmed != true) return;

      // 4. 写入数据库
      _showLoading(navCtx, '正在导入课程...');

      final semRepo = SemesterRepository();
      final courseRepo = CourseRepository();

      // 查找或创建学期
      final semesters = ref.read(semesterProvider).semesters;
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
        // 自动创建学期（根据学期名称推算天大开学日期）
        final startDate =
            CourseImportService.estimateSemesterStart(importResult.semesterName);
        final newSem = Semester(
          name: importResult.semesterName,
          startDate: startDate,
          endDate: startDate.add(const Duration(days: 18 * 7 - 1)),
          totalWeeks: 18,
          isCurrent: semesters.isEmpty,
        );
        semesterId = await semRepo.insert(newSem);
        await ref.read(semesterProvider.notifier).loadSemesters();
      }

      // 批量插入课程
      for (final course in importResult.courses) {
        final c = course.copyWith(semesterId: semesterId);
        await courseRepo.insert(c);
      }

      // 刷新 UI
      await ref.read(courseProvider.notifier).loadCourses();

      nav?.pop(); // dismiss loading

      // 5. 成功提示
      showDialog(
        context: navCtx,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('导入成功'),
          content: Text('已导入 ${importResult.courseCount} 门课程\n学期：${importResult.semesterName}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('好的'),
            ),
          ],
        ),
      );
    } catch (e) {
      // dismiss any loading dialog
      nav?.pop();
      _showError(navCtx, '导入失败', e.toString());
    }
  }

  static void _showLoading(BuildContext context, String msg) {
    showDialog(
      context: rootNavigatorKey.currentContext ?? context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(msg),
          ],
        ),
      ),
    );
  }

  static void _showError(BuildContext context, String title, String detail) {
    showDialog(
      context: rootNavigatorKey.currentContext ?? context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: Text(title),
        content: detail.isNotEmpty ? Text(detail, style: const TextStyle(fontSize: 13)) : null,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('好的')),
        ],
      ),
    );
  }

  static Future<bool?> _showConfirmDialog(
    BuildContext context,
    String semesterName,
    int courseCount,
    List<String> warnings,
  ) {
    return showDialog<bool>(
      context: rootNavigatorKey.currentContext ?? context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.table_chart, size: 48),
        title: const Text('确认导入课表'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('学期：$semesterName'),
            const SizedBox(height: 4),
            Text('课程数：$courseCount 门'),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('⚠ 注意事项：', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ...warnings.take(3).map((w) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('· $w', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认导入')),
        ],
      ),
    );
  }
}
