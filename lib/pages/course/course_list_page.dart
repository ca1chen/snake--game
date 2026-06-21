import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../router/app_router.dart';

/// 课程列表管理页
class CourseListPage extends ConsumerWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseState = ref.watch(courseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('课程管理')),
      body: courseState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : courseState.courses.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.book_outlined,
                  title: '还没有课程',
                  subtitle: '点击右下角按钮添加第一门课程',
                  actionLabel: '添加课程',
                  onAction: () => AppRouter.goCourseAdd(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: courseState.courses.length,
                  itemBuilder: (context, index) {
                    final course = courseState.courses[index];
                    final color = Color(
                      int.parse('FF${course.color.replaceFirst('#', '')}', radix: 16),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      child: ListTile(
                        leading: Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(course.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          '${course.teacher} · ${course.classroom}\n${_weekdayLabel(course.dayOfWeek)} 第${course.startPeriod}-${course.startPeriod + course.duration - 1}节 · 第${course.startWeek}-${course.endWeek}周${_weekTypeLabel(course.weekType)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'edit') {
                              AppRouter.goCourseEdit(context, course.id!);
                            } else if (action == 'delete') {
                              final ok = await ConfirmDialog.show(
                                context,
                                title: '删除课程',
                                content: '删除「${course.name}」？关联的待办不会被删除。',
                                confirmLabel: '删除',
                                confirmColor: Colors.red,
                              );
                              if (ok == true) {
                                await ref.read(courseProvider.notifier).deleteCourse(course.id!);
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('编辑')),
                            const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                        onTap: () => AppRouter.goCourseDetail(context, course.id!),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppRouter.goCourseAdd(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _weekdayLabel(int day) => const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][day - 1];

  String _weekTypeLabel(WeekType type) {
    switch (type) {
      case WeekType.every: return '';
      case WeekType.odd: return ' (单)';
      case WeekType.even: return ' (双)';
    }
  }
}
