import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/todo_item.dart';
import 'priority_badge_widget.dart';

/// 待办卡片组件
class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final String? courseName;
  final String? courseColor;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    this.courseName,
    this.courseColor,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = todo.isOverdue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 完成勾选框
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: todo.isCompleted ? Colors.green : theme.colorScheme.outline,
                      width: 2,
                    ),
                    color: todo.isCompleted ? Colors.green : null,
                  ),
                  child: todo.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PriorityBadge(priority: todo.priority.index),
                        if (courseName != null) ...[
                          const SizedBox(width: 6),
                          _CourseTag(name: courseName!, colorHex: courseColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      todo.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        color: todo.isCompleted
                            ? theme.colorScheme.onSurface.withOpacity(0.4)
                            : (isOverdue ? Colors.red : null),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 13, color: isOverdue ? Colors.red : theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(todo.dueDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverdue ? Colors.red : theme.colorScheme.outline,
                          ),
                        ),
                        if (todo.dueTime != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 13, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(todo.dueTime!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 删除按钮
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error.withOpacity(0.6)),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == -1) return '昨天';
    return DateFormat('M月d日').format(date);
  }
}

/// 课程标签小部件
class _CourseTag extends StatelessWidget {
  final String name;
  final String? colorHex;

  const _CourseTag({required this.name, this.colorHex});

  @override
  Widget build(BuildContext context) {
    final color = colorHex != null
        ? Color(int.parse('FF${colorHex!.replaceFirst('#', '')}', radix: 16))
        : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
