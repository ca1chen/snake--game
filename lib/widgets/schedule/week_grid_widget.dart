import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../utils/constants.dart';
import 'course_card_widget.dart';

/// 周视图课程表网格（7列 x N行）
class WeekGrid extends StatelessWidget {
  final Map<int, List<Course>> coursesByDay; // key: dayOfWeek(1-7)
  final int startPeriod;    // 显示起始节数（默认1）
  final int displayPeriods; // 显示多少节课（默认6）
  final Map<int, int> todoCountMap; // courseId -> incompleteTodoCount
  final void Function(Course course)? onCourseTap;
  final void Function(Course course)? onCourseLongPress;

  const WeekGrid({
    super.key,
    required this.coursesByDay,
    this.startPeriod = 1,
    this.displayPeriods = 6,
    this.todoCountMap = const {},
    this.onCourseTap,
    this.onCourseLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: List.generate(displayPeriods, (row) {
        final period = startPeriod + row;
        return SizedBox(
          height: 72,
          child: Row(
            children: [
              // 左侧节数标签
              _buildPeriodLabel(context, period, theme),
              // 7 天列
              ...List.generate(7, (col) {
                final day = col + 1;
                final courses = _findCoursesAt(day, period);
                return Expanded(
                  child: _buildCell(context, day, period, courses, theme),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPeriodLabel(BuildContext context, int period, ThemeData theme) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.15)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$period',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            periodTimeMap[period]?.split(' - ').first ?? '',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline.withOpacity(0.5),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, int day, int period, List<Course> courses, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: Stack(
        children: courses.map((course) {
          // 判断是否是本节的起始课程
          if (course.startPeriod != period) {
            return const SizedBox.shrink();
          }
          // 计算跨越行数
          final spanCount = course.duration;
          final todoCount = todoCountMap[course.id] ?? 0;

          return Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 72 * spanCount - 2,
            child: CourseCard(
              course: course,
              incompleteTodoCount: todoCount,
              onTap: () => onCourseTap?.call(course),
              onLongPress: () => onCourseLongPress?.call(course),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 查找某天某节的课程
  List<Course> _findCoursesAt(int day, int period) {
    final dayCourses = coursesByDay[day] ?? [];
    return dayCourses.where((c) {
      // 课程覆盖这个节次
      return period >= c.startPeriod && period < c.startPeriod + c.duration;
    }).toList();
  }
}
