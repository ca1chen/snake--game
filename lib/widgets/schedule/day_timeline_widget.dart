import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../utils/constants.dart';
import 'course_card_widget.dart';

/// 日视图时间线组件
class DayTimeline extends StatelessWidget {
  final List<Course> courses;
  final int dayOfWeek;      // 1-7
  final String dateLabel;   // "10月15日 周一"
  final Map<int, int> todoCountMap; // courseId -> count
  final void Function(Course)? onCourseTap;

  const DayTimeline({
    super.key,
    required this.courses,
    required this.dayOfWeek,
    required this.dateLabel,
    this.todoCountMap = const {},
    this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...courses]..sort((a, b) => a.startPeriod.compareTo(b.startPeriod));
    final maxPeriod = _getMaxPeriod();

    if (sorted.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('当天没有课程', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: maxPeriod,
      itemBuilder: (context, index) {
        final period = index + 1;
        final coursesAtPeriod = sorted.where((c) => c.startPeriod == period).toList();

        if (coursesAtPeriod.isEmpty && !_hasOngoingCourse(sorted, period)) {
          return _buildEmptyPeriod(context, period, theme);
        }

        // 只渲染起始节
        if (coursesAtPeriod.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间标签
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      periodTimeMap[period] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 课程卡片
              ...coursesAtPeriod.map((course) {
                final height = 72.0 * course.duration - 4;
                return Expanded(
                  child: SizedBox(
                    height: height,
                    child: CourseCard(
                      course: course,
                      incompleteTodoCount: todoCountMap[course.id] ?? 0,
                      onTap: () => onCourseTap?.call(course),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyPeriod(BuildContext context, int period, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              periodTimeMap[period] ?? '',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.dividerColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasOngoingCourse(List<Course> courses, int period) {
    return courses.any((c) =>
        period > c.startPeriod && period < c.startPeriod + c.duration);
  }

  int _getMaxPeriod() {
    if (courses.isEmpty) return defaultDisplayPeriods;
    int max = 0;
    for (final c in courses) {
      final end = c.startPeriod + c.duration - 1;
      if (end > max) max = end;
    }
    return max > defaultDisplayPeriods ? max : defaultDisplayPeriods;
  }
}
