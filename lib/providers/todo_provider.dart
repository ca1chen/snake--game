import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo_item.dart';
import '../repositories/todo_repository.dart';

/// 待办筛选条件
enum TodoFilter {
  all,        // 全部
  incomplete, // 未完成
  completed,  // 已完成
  highPriority, // 高优先级
  overdue,    // 逾期
}

/// 待办列表状态
class TodoState {
  final List<TodoItem> todos;
  final TodoFilter filter;
  final bool isLoading;
  final String? error;

  const TodoState({
    this.todos = const [],
    this.filter = TodoFilter.all,
    this.isLoading = false,
    this.error,
  });

  /// 获取筛选后的待办列表
  List<TodoItem> get filteredTodos {
    switch (filter) {
      case TodoFilter.all:
        return todos;
      case TodoFilter.incomplete:
        return todos.where((t) => !t.isCompleted).toList();
      case TodoFilter.completed:
        return todos.where((t) => t.isCompleted).toList();
      case TodoFilter.highPriority:
        return todos.where((t) => t.priority == Priority.high && !t.isCompleted).toList();
      case TodoFilter.overdue:
        return todos.where((t) => t.isOverdue).toList();
    }
  }

  /// 未完成数量
  int get incompleteCount => todos.where((t) => !t.isCompleted).length;

  /// 逾期未完成数量
  int get overdueCount => todos.where((t) => t.isOverdue).length;

  TodoState copyWith({
    List<TodoItem>? todos,
    TodoFilter? filter,
    bool? isLoading,
    String? error,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 待办管理 Provider
class TodoNotifier extends StateNotifier<TodoState> {
  final TodoRepository _repo = TodoRepository();

  TodoNotifier() : super(const TodoState()) {
    loadTodos();
  }

  /// 加载所有待办
  Future<void> loadTodos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final todos = await _repo.getAll();
      state = state.copyWith(todos: todos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 设置筛选条件
  void setFilter(TodoFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// 添加待办
  Future<void> addTodo(TodoItem todo) async {
    try {
      await _repo.insert(todo);
      await loadTodos();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 更新待办
  Future<void> updateTodo(TodoItem todo) async {
    try {
      await _repo.update(todo);
      await loadTodos();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 删除待办
  Future<void> deleteTodo(int id) async {
    try {
      await _repo.delete(id);
      await loadTodos();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 切换完成状态
  Future<void> toggleComplete(int id) async {
    try {
      await _repo.toggleComplete(id);
      await loadTodos();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 获取某课程已完成的待办数
  int completedCountByCourse(int courseId) {
    return state.todos
        .where((t) => t.courseId == courseId && t.isCompleted)
        .length;
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>((ref) {
  return TodoNotifier();
});

/// 某课程未完成待办数量 Provider
final courseTodoCountProvider = Provider.family<int, int>((ref, courseId) {
  final todoState = ref.watch(todoProvider);
  return todoState.todos
      .where((t) => t.courseId == courseId && !t.isCompleted)
      .length;
});

/// 某课程所有待办 Provider
final courseTodosProvider = Provider.family<List<TodoItem>, int>((ref, courseId) {
  final todoState = ref.watch(todoProvider);
  return todoState.todos.where((t) => t.courseId == courseId).toList();
});
