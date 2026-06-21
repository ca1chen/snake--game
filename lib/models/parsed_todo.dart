import 'todo_item.dart';

/// 语音解析后的中间待办数据
/// 用户确认编辑后通过 [toTodoItem] 转为正式的 TodoItem 持久化
class ParsedTodo {
  final int index;
  String title;
  Priority priority;
  String dueDate; // yyyy-MM-dd
  String? dueTime; // HH:mm，null 表示全天
  final String rawText; // 原始语音片段（仅展示用）

  ParsedTodo({
    required this.index,
    required this.title,
    this.priority = Priority.medium,
    String? dueDate,
    this.dueTime,
    this.rawText = '',
  }) : dueDate = dueDate ??
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

  /// 转为正式的 TodoItem
  TodoItem toTodoItem() => TodoItem(
        title: title,
        priority: priority,
        dueDate: dueDate,
        dueTime: dueTime,
      );
}
