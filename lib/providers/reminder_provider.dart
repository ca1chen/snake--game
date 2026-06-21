import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
import '../repositories/reminder_repository.dart';

/// 提醒列表状态
class ReminderState {
  final List<Reminder> reminders;
  final bool isLoading;
  final String? error;

  const ReminderState({
    this.reminders = const [],
    this.isLoading = false,
    this.error,
  });

  ReminderState copyWith({
    List<Reminder>? reminders,
    bool? isLoading,
    String? error,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 提醒管理 Provider
class ReminderNotifier extends StateNotifier<ReminderState> {
  final ReminderRepository _repo = ReminderRepository();

  ReminderNotifier() : super(const ReminderState()) {
    Future.microtask(() => loadAll());
  }

  /// 加载所有提醒
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final reminders = await _repo.getPendingReminders();
      state = state.copyWith(reminders: reminders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 添加提醒
  Future<int> addReminder(Reminder reminder) async {
    final id = await _repo.insert(reminder);
    await loadAll();
    return id;
  }

  /// 删除提醒
  Future<void> deleteReminder(int id) async {
    await _repo.delete(id);
    await loadAll();
  }

  /// 删除某待办的所有提醒
  Future<void> deleteByTodoId(int todoId) async {
    await _repo.deleteByTodoId(todoId);
    await loadAll();
  }

  /// 获取某待办的提醒列表
  Future<List<Reminder>> getByTodo(int todoId) async {
    return await _repo.getByTodo(todoId);
  }

  /// 标记已触发
  Future<void> markTriggered(int id) async {
    await _repo.markTriggered(id);
    await loadAll();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier();
});
