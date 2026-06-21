import 'todo_item.dart';

/// 语音解析后的中间数据模型，用户确认后转为 TodoItem
class ParsedTodo {
  final int index;
  String title;
  Priority priority;
  String dueDate;
  String? dueTime;
  final String rawText;

  ParsedTodo({
    required this.index,
    required this.title,
    this.priority = Priority.medium,
    required this.dueDate,
    this.dueTime,
    this.rawText = '',
  });

  TodoItem toTodoItem() => TodoItem(
        title: title,
        priority: priority,
        dueDate: dueDate,
        dueTime: dueTime,
      );
}
