import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';
import '../../providers/todo_provider.dart';
import '../../widgets/todo/todo_card_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../router/app_router.dart';
import '../../utils/constants.dart';
import '../../models/todo_item.dart';

/// 课程详情页 — 展示课程信息 + 绑定待办列表
class CourseDetailPage extends ConsumerWidget {
  final int courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseState = ref.watch(courseProvider);
    final todoState = ref.watch(todoProvider);

    final course = courseState.courses.where((c) => c.id == courseId).firstOrNull;
    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('课程详情')),
        body: const Center(child: Text('课程未找到')),
      );
    }

    final color = parseHexColor(course.color);
    final boundTodos = todoState.todos.where((t) => t.courseId == courseId).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.dueDate.compareTo(b.dueDate);
      });
    final incompleteTodos = boundTodos.where((t) => !t.isCompleted).toList();
    final completedTodos = boundTodos.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _editCourse(context, course),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 课程信息卡片
          Card(
            color: color.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 24,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          course.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow(context,Icons.person_outline, '教师', course.teacher.isNotEmpty ? course.teacher : '未设置'),
                  const SizedBox(height: 6),
                  _infoRow(context,Icons.location_on_outlined, '教室', course.classroom.isNotEmpty ? course.classroom : '未设置'),
                  const SizedBox(height: 6),
                  _infoRow(context,Icons.schedule, '时间', '${weekdayLabels[course.dayOfWeek - 1]} 第${course.startPeriod}-${course.startPeriod + course.duration - 1}节'),
                  const SizedBox(height: 6),
                  _infoRow(context,Icons.date_range, '周次', '第${course.startWeek}-${course.endWeek}周${_weekTypeLabel(course.weekType)}'),
                  if (course.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _infoRow(context,Icons.notes, '备注', course.notes),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 待办统计 + 添加按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '关联待办 (${boundTodos.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _addTodoForCourse(context, course),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新增'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 未完成待办
          if (incompleteTodos.isEmpty && completedTodos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: EmptyStateWidget(
                icon: Icons.task_alt,
                title: '还没有关联待办',
                subtitle: '为此课程添加作业、复习、预习等任务',
              ),
            )
          else ...[
            if (incompleteTodos.isNotEmpty) ...[
              Text(
                '未完成 (${incompleteTodos.length})',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
              ...incompleteTodos.map((todo) => TodoCard(
                    todo: todo,
                    onTap: () => AppRouter.goTodoDetail(context, todo.id!),
                    onToggle: () => ref.read(todoProvider.notifier).toggleComplete(todo.id!),
                    onDelete: () => _deleteTodo(context, ref, todo),
                  )),
            ],
            if (completedTodos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '已完成 (${completedTodos.length})',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
              ...completedTodos.map((todo) => TodoCard(
                    todo: todo,
                    onTap: () => AppRouter.goTodoDetail(context, todo.id!),
                    onToggle: () => ref.read(todoProvider.notifier).toggleComplete(todo.id!),
                    onDelete: () => _deleteTodo(context, ref, todo),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext ctx, IconData icon, String label, String value) {
    final theme = Theme.of(ctx);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
      ],
    );
  }

  String _weekTypeLabel(WeekType type) {
    switch (type) {
      case WeekType.every: return '';
      case WeekType.odd: return '(单周)';
      case WeekType.even: return '(双周)';
    }
  }

  void _editCourse(BuildContext context, Course course) {
    AppRouter.goCourseEdit(context, course.id!);
  }

  void _addTodoForCourse(BuildContext context, Course course) {
    AppRouter.goTodoAdd(context, courseId: course.id);
  }

  Future<void> _deleteTodo(BuildContext context, WidgetRef ref, TodoItem todo) async {
    final ok = await ConfirmDialog.show(
      context,
      title: '删除待办',
      content: '确定删除「${todo.title}」？',
      confirmLabel: '删除',
      confirmColor: Colors.red,
    );
    if (ok == true) {
      await ref.read(todoProvider.notifier).deleteTodo(todo.id!);
    }
  }
}
