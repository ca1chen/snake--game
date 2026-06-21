import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo_item.dart';
import '../../models/course.dart';
import '../../providers/todo_provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/todo/todo_card_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../router/app_router.dart';

/// 待办列表页面
class TodoListPage extends ConsumerWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoState = ref.watch(todoProvider);
    final courseState = ref.watch(courseProvider);
    final theme = Theme.of(context);

    final filteredTodos = todoState.filteredTodos;

    // 构建 courseId -> Course 的快速映射
    final courseMap = <int, Course>{};
    for (final c in courseState.courses) {
      if (c.id != null) courseMap[c.id!] = c;
    }

    return Column(
      children: [
        // 筛选栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TodoFilter.values.map((filter) {
                final isSelected = todoState.filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(_filterLabel(filter)),
                    selected: isSelected,
                    onSelected: (_) => ref.read(todoProvider.notifier).setFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // 统计信息
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '共 ${filteredTodos.length} 项',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
              if (todoState.filter == TodoFilter.all) ...[
                const SizedBox(width: 12),
                if (todoState.overdueCount > 0)
                  Text(
                    '${todoState.overdueCount} 项逾期',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.red),
                  ),
              ],
            ],
          ),
        ),

        // 待办列表
        Expanded(
          child: todoState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredTodos.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.task_alt,
                      title: _emptyTitle(todoState.filter),
                      subtitle: '点击右下角按钮添加新任务',
                      actionLabel: '添加任务',
                      onAction: () => AppRouter.goTodoAdd(context),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 80),
                      itemCount: filteredTodos.length,
                      itemBuilder: (context, index) {
                        final todo = filteredTodos[index];
                        Course? course;
                        String? courseName;
                        String? courseColor;
                        if (todo.courseId != null) {
                          course = courseMap[todo.courseId];
                          courseName = course?.name;
                          courseColor = course?.color;
                        }

                        return TodoCard(
                          todo: todo,
                          courseName: courseName,
                          courseColor: courseColor,
                          onTap: () => AppRouter.goTodoDetail(context, todo.id!),
                          onToggle: () => ref.read(todoProvider.notifier).toggleComplete(todo.id!),
                          onDelete: () => _deleteTodo(context, ref, todo),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _filterLabel(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all: return '全部';
      case TodoFilter.incomplete: return '未完成';
      case TodoFilter.completed: return '已完成';
      case TodoFilter.highPriority: return '高优先级';
      case TodoFilter.overdue: return '已逾期';
    }
  }

  String _emptyTitle(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all: return '还没有待办任务';
      case TodoFilter.incomplete: return '没有未完成任务';
      case TodoFilter.completed: return '没有已完成任务';
      case TodoFilter.highPriority: return '没有高优先级任务';
      case TodoFilter.overdue: return '没有逾期任务';
    }
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
