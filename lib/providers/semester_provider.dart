import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/semester.dart';
import '../repositories/semester_repository.dart';

/// 学期列表状态
class SemesterState {
  final List<Semester> semesters;
  final Semester? currentSemester;
  final bool isLoading;
  final String? error;

  const SemesterState({
    this.semesters = const [],
    this.currentSemester,
    this.isLoading = false,
    this.error,
  });

  SemesterState copyWith({
    List<Semester>? semesters,
    Semester? currentSemester,
    bool? isLoading,
    String? error,
  }) {
    return SemesterState(
      semesters: semesters ?? this.semesters,
      currentSemester: currentSemester ?? this.currentSemester,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 学期管理 Provider
class SemesterNotifier extends StateNotifier<SemesterState> {
  final SemesterRepository _repo = SemesterRepository();

  SemesterNotifier() : super(const SemesterState()) {
    loadSemesters();
  }

  /// 加载所有学期
  Future<void> loadSemesters() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final semesters = await _repo.getAll();
      final current = await _repo.getCurrent();
      state = state.copyWith(
        semesters: semesters,
        currentSemester: current,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 添加新学期
  Future<void> addSemester(Semester semester) async {
    try {
      await _repo.insert(semester);
      await loadSemesters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 更新学期
  Future<void> updateSemester(Semester semester) async {
    try {
      await _repo.update(semester);
      await loadSemesters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 删除学期
  Future<void> deleteSemester(int id) async {
    try {
      await _repo.delete(id);
      await loadSemesters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 设置当前学期
  Future<void> setCurrentSemester(int id) async {
    try {
      await _repo.setCurrent(id);
      await loadSemesters();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final semesterProvider =
    StateNotifierProvider<SemesterNotifier, SemesterState>((ref) {
  return SemesterNotifier();
});
