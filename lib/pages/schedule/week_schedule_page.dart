import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/semester.dart';
import '../../providers/semester_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/todo_provider.dart';
import '../../widgets/schedule/schedule_header_widget.dart';
import '../../widgets/schedule/week_grid_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../router/app_router.dart';

/// 周视图课程表页面
class WeekSchedulePage extends ConsumerWidget {
  const WeekSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semesterState = ref.watch(semesterProvider);
    final courseState = ref.watch(courseProvider);
    final todoState = ref.watch(todoProvider);

    // 构建课程-待办计数映射
    final todoCountMap = <int, int>{};
    for (final todo in todoState.todos) {
      if (todo.courseId != null && !todo.isCompleted) {
        todoCountMap[todo.courseId!] = (todoCountMap[todo.courseId!] ?? 0) + 1;
      }
    }

    return Column(
      children: [
        // 表头
        ScheduleHeader(
          currentSemester: semesterState.currentSemester,
          currentWeek: courseState.currentWeek,
          onPrevWeek: () {
            if (courseState.currentWeek > 1) {
              ref.read(courseProvider.notifier).setWeek(courseState.currentWeek - 1);
            }
          },
          onNextWeek: () {
            final maxWeek = semesterState.currentSemester?.totalWeeks ?? 20;
            if (courseState.currentWeek < maxWeek) {
              ref.read(courseProvider.notifier).setWeek(courseState.currentWeek + 1);
            }
          },
          onTapToday: () {
            // 跳转到当前周
            if (semesterState.currentSemester != null) {
              final todayWeek = _getTodayWeek(semesterState.currentSemester!);
              if (todayWeek > 0) {
                ref.read(courseProvider.notifier).setWeek(todayWeek);
              }
            }
          },
          onTapDayView: () {
            AppRouter.goScheduleDay(context);
          },
        ),
        // 课程表主体（支持左右滑动切换周次）
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              // 左滑（负速度）→ 下一周，右滑（正速度）→ 上一周
              if (details.primaryVelocity! < -100) {
                final maxWeek = semesterState.currentSemester?.totalWeeks ?? 20;
                if (courseState.currentWeek < maxWeek) {
                  ref.read(courseProvider.notifier).setWeek(courseState.currentWeek + 1);
                }
              } else if (details.primaryVelocity! > 100) {
                if (courseState.currentWeek > 1) {
                  ref.read(courseProvider.notifier).setWeek(courseState.currentWeek - 1);
                }
              }
            },
            child: courseState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : semesterState.currentSemester == null
                    ? EmptyStateWidget(
                        icon: Icons.school_outlined,
                        title: '请先设置学期',
                        subtitle: '在设置中添加一个学期开始使用',
                      )
                    : courseState.coursesByDay.isEmpty ||
                           courseState.coursesByDay.values.every((l) => l.isEmpty)
                        ? EmptyStateWidget(
                            icon: Icons.grid_view_rounded,
                            title: '本周没有课程',
                            subtitle: '点击右下角按钮添加课程',
                            actionLabel: '添加课程',
                            onAction: () {
                              AppRouter.goCourseAdd(context);
                            },
                          )
                        : WeekGrid(
                            coursesByDay: courseState.coursesByDay,
                            displayPeriods: 6,
                            todoCountMap: todoCountMap,
                            onCourseTap: (course) {
                              AppRouter.goCourseDetail(context, course.id!);
                            },
                          ),
          ),
        ),
      ],
    );
  }

  int _getTodayWeek(Semester semester) {
    final diff = DateTime.now().difference(semester.startDate).inDays;
    if (diff < 0) return 1;
    final week = (diff / 7).floor() + 1;
    if (week > semester.totalWeeks) return semester.totalWeeks;
    return week;
  }
}
