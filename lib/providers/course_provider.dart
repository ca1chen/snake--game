import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import '../utils/date_utils.dart' as DateHelper;
import 'semester_provider.dart';

/// 课程列表状态
class CourseState {
  final List<Course> courses;
  final Map<int, List<Course>> coursesByDay; // key: dayOfWeek(1-7)
  final int currentWeek;
  final bool isLoading;
  final String? error;

  const CourseState({
    this.courses = const [],
    this.coursesByDay = const {},
    this.currentWeek = 1,
    this.isLoading = false,
    this.error,
  });

  CourseState copyWith({
    List<Course>? courses,
    Map<int, List<Course>>? coursesByDay,
    int? currentWeek,
    bool? isLoading,
    String? error,
  }) {
    return CourseState(
      courses: courses ?? this.courses,
      coursesByDay: coursesByDay ?? this.coursesByDay,
      currentWeek: currentWeek ?? this.currentWeek,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 课程管理 Provider
class CourseNotifier extends StateNotifier<CourseState> {
  final CourseRepository _repo = CourseRepository();
  final SemesterNotifier _semesterNotifier;

  CourseNotifier(this._semesterNotifier) : super(const CourseState());

  /// 加载当前学期的课程
  Future<void> loadCourses() async {
    final semester = _semesterNotifier.state.currentSemester;
    final semesterId = semester?.id;
    if (semesterId == null) {
      state = state.copyWith(courses: [], coursesByDay: {}, isLoading: false);
      return;
    }
    // 自动计算当前周次（如果从未设置过）
    var week = state.currentWeek;
    if (week <= 1) {
      week = DateHelper.DateUtils.getWeekNumber(semester!.startDate, DateTime.now());
      if (week < 1) week = 1;
      if (week > semester!.totalWeeks) week = semester!.totalWeeks;
    }

    state = state.copyWith(currentWeek: week, isLoading: true, error: null);
    try {
      final courses = await _repo.getBySemester(semesterId);
      final byDay = await _repo.getActiveForWeek(
        semesterId,
        week,
      );
      state = state.copyWith(
        courses: courses,
        coursesByDay: byDay,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 设置当前周次并重新加载
  Future<void> setWeek(int week) async {
    state = state.copyWith(currentWeek: week);
    await loadCourses();
  }

  /// 添加课程
  Future<void> addCourse(Course course) async {
    try {
      await _repo.insert(course);
      await loadCourses();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 更新课程
  Future<void> updateCourse(Course course) async {
    try {
      await _repo.update(course);
      await loadCourses();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 删除课程
  Future<void> deleteCourse(int id) async {
    try {
      await _repo.delete(id);
      await loadCourses();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 检测时间冲突
  Future<List<Course>> checkConflict({
    required int semesterId,
    required int dayOfWeek,
    required int startPeriod,
    required int duration,
    int? excludeCourseId,
  }) async {
    return await _repo.checkConflict(
      semesterId: semesterId,
      dayOfWeek: dayOfWeek,
      startPeriod: startPeriod,
      duration: duration,
      excludeCourseId: excludeCourseId,
    );
  }

  /// 获取当前周次
  int getCurrentWeek() => state.currentWeek;

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final courseProvider =
    StateNotifierProvider<CourseNotifier, CourseState>((ref) {
  final semesterNotifier = ref.read(semesterProvider.notifier);
  return CourseNotifier(semesterNotifier);
});
