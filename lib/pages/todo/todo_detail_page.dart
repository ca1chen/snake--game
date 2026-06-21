import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/todo_provider.dart';
import '../../providers/course_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/todo/priority_badge_widget.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../router/app_router.dart';

/// 待办详情页面
class TodoDetailPage extends ConsumerWidget {
  final int todoId;

  const TodoDetailPage({super.key, required this.todoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoState = ref.watch(todoProvider);
    final courseState = ref.watch(courseProvider);
    final theme = Theme.of(context);

    final todo = todoState.todos.where((t) => t.id == todoId).firstOrNull;
    if (todo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('待办详情')),
        body: const Center(child: Text('待办未找到')),
      );
    }

    final course = todo.courseId != null
        ? courseState.courses.where((c) => c.id == todo.courseId).firstOrNull
        : null;
    final color = course != null ? parseHexColor(course.color) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('待办详情'),
        actions: [
          IconButton(
            icon: Icon(Icons.check_circle_outline, color: todo.isCompleted ? Colors.green : null),
            onPressed: () => ref.read(todoProvider.notifier).toggleComplete(todo.id!),
            tooltip: todo.isCompleted ? '标记未完成' : '标记完成',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => AppRouter.goTodoEdit(context, todo.id!),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 状态条
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: todo.isCompleted ? Colors.green.withOpacity(0.1) : (todo.isOverdue ? Colors.red.withOpacity(0.1) : null),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: todo.isCompleted ? Colors.green.withOpacity(0.3) : (todo.isOverdue ? Colors.red.withOpacity(0.3) : Colors.transparent),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  todo.isCompleted ? Icons.check_circle : (todo.isOverdue ? Icons.warning_amber : Icons.pending),
                  size: 18,
                  color: todo.isCompleted ? Colors.green : (todo.isOverdue ? Colors.red : Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  todo.isCompleted ? '已完成' : (todo.isOverdue ? '已逾期' : '进行中'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: todo.isCompleted ? Colors.green : (todo.isOverdue ? Colors.red : Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 标题
          Text(todo.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),

          const SizedBox(height: 16),

          // 元信息
          _metaRow(theme, Icons.flag_outlined, '优先级', PriorityBadge(priority: todo.priority.index)),
          const SizedBox(height: 10),
          _metaRow(theme, Icons.calendar_today, '截止日期', Text(todo.dueDate)),
          if (todo.dueTime != null) ...[
            const SizedBox(height: 10),
            _metaRow(theme, Icons.access_time, '截止时间', Text(todo.dueTime!)),
          ],
          if (course != null) ...[
            const SizedBox(height: 10),
            _metaRow(
              theme,
              Icons.book_outlined,
              '关联课程',
              GestureDetector(
                onTap: () => AppRouter.goCourseDetail(context, course.id!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(course.name, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ],

          if (todo.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('备注', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(todo.description, style: theme.textTheme.bodyMedium),
            ),
          ],

          const SizedBox(height: 32),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: todo.isCompleted
                      ? null
                      : () => ref.read(todoProvider.notifier).toggleComplete(todo.id!),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('标记完成'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await ConfirmDialog.show(
                      context,
                      title: '删除待办',
                      content: '确定删除「${todo.title}」？',
                      confirmLabel: '删除',
                      confirmColor: Colors.red,
                    );
                    if (ok == true) {
                      await ref.read(todoProvider.notifier).deleteTodo(todo.id!);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                  label: Text('删除', style: TextStyle(color: theme.colorScheme.error)),
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(ThemeData theme, IconData icon, String label, Widget value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        SizedBox(width: 72, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))),
        value,
      ],
    );
  }
}
