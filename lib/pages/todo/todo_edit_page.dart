import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo_item.dart';
import '../../models/reminder.dart';
import '../../providers/todo_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../services/notification_service.dart';

/// 待办编辑页面（添加/编辑）
class TodoEditPage extends ConsumerStatefulWidget {
  final TodoItem? todo;     // null = 添加模式
  final int? courseId;      // 预设关联课程

  const TodoEditPage({super.key, this.todo, this.courseId});

  @override
  ConsumerState<TodoEditPage> createState() => _TodoEditPageState();
}

class _TodoEditPageState extends ConsumerState<TodoEditPage> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  late Priority _priority;
  late String _dueDate;
  String? _dueTime;
  int? _courseId;
  final List<int> _reminderMinutes = []; // 已选提醒

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? Priority.medium;
    _dueDate = t?.dueDate ?? DateTime.now().toIso8601String().split('T').first;
    _dueTime = t?.dueTime;
    _courseId = t?.courseId ?? widget.courseId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务名称')),
      );
      return;
    }

    final todo = TodoItem(
      id: widget.todo?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      dueTime: _dueTime,
      isCompleted: widget.todo?.isCompleted ?? false,
      courseId: _courseId,
    );

    if (isEditing) {
      await ref.read(todoProvider.notifier).updateTodo(todo);
    } else {
      await ref.read(todoProvider.notifier).addTodo(todo);
    }

    // 处理提醒
    if (isEditing) {
      // 先删除旧提醒再添加新提醒
      await ref.read(reminderProvider.notifier).deleteByTodoId(todo.id!);
    }
    // 重新获取刚插入/更新的待办的 ID
    final todoState = ref.read(todoProvider);
    final savedTodo = isEditing ? todo : todoState.todos.lastOrNull;
    if (savedTodo != null && _reminderMinutes.isNotEmpty) {
      for (final minutes in _reminderMinutes) {
        final reminderId = await ref.read(reminderProvider.notifier).addReminder(
              Reminder(todoId: savedTodo.id!, remindMinutes: minutes),
            );
        // 调度通知
        await NotificationService.scheduleTodoReminder(
          id: reminderId,
          todoTitle: todo.title,
          dueDate: _dueDate,
          dueTime: _dueTime,
          remindMinutes: minutes,
        );
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _dueDate = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      setState(() => _dueTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseState = ref.watch(courseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑待办' : '添加待办'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: '任务名称', hintText: '完成高数作业 P45-P48'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),

            // 描述
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: '备注', hintText: '可选的详细描述'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // 优先级
            Text('优先级', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            SegmentedButton<Priority>(
              segments: const [
                ButtonSegment(value: Priority.low, label: Text('低'), icon: Icon(Icons.flag, size: 16, color: Colors.grey)),
                ButtonSegment(value: Priority.medium, label: Text('中'), icon: Icon(Icons.flag, size: 16, color: Colors.orange)),
                ButtonSegment(value: Priority.high, label: Text('高'), icon: Icon(Icons.flag, size: 16, color: Colors.red)),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),

            const SizedBox(height: 16),

            // 截止日期
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('截止日期'),
                    subtitle: Text(_dueDate),
                    onTap: _pickDate,
                  ),
                ),
                if (_dueTime != null)
                  TextButton(onPressed: () => setState(() => _dueTime = null), child: const Text('清除时间')),
              ],
            ),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time, size: 18),
              label: Text(_dueTime ?? '添加时间'),
            ),

            const SizedBox(height: 16),

            // 关联课程
            Text('关联课程', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              value: _courseId,
              decoration: const InputDecoration(hintText: '选择课程（可选）'),
              items: [
                const DropdownMenuItem(value: null, child: Text('无关联课程')),
                ...courseState.courses.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )),
              ],
              onChanged: (v) => setState(() => _courseId = v),
            ),

            const SizedBox(height: 16),

            // 提醒设置
            Text('提醒设置', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: Reminder.presetOptions.map((min) {
                final isSelected = _reminderMinutes.contains(min);
                return FilterChip(
                  label: Text(Reminder.formatMinutes(min)),
                  selected: isSelected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _reminderMinutes.add(min);
                      } else {
                        _reminderMinutes.remove(min);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('保存任务')),
            ),
          ],
        ),
      ),
    );
  }
}
