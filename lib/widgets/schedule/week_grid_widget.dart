import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../utils/constants.dart';
import 'course_card_widget.dart';

/// 周视图课程表网格（7列 x N行）
///
/// 左栏：节次标签（3行格式）
/// 右栏：Stack 分层 — 底层网格线，顶层课程卡片绝对定位
/// 跨多节课程通过 Positioned(height > rowHeight) 自然跨越，且不被后续行遮挡
class WeekGrid extends StatelessWidget {
  final Map<int, List<Course>> coursesByDay; // key: dayOfWeek(1-7)
  final int startPeriod;
  final int displayPeriods;
  final Map<int, int> todoCountMap; // courseId -> incompleteTodoCount
  final void Function(Course course)? onCourseTap;
  final void Function(Course course)? onCourseLongPress;

  static const double periodLabelWidth = 48;
  static const double rowHeight = 72;

  const WeekGrid({
    super.key,
    required this.coursesByDay,
    this.startPeriod = 1,
    this.displayPeriods = defaultDisplayPeriods,
    this.todoCountMap = const {},
    this.onCourseTap,
    this.onCourseLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左栏：节次标签
            Column(
              children: List.generate(displayPeriods, (i) {
                final period = startPeriod + i;
                return SizedBox(
                  height: rowHeight,
                  child: _buildPeriodLabel(period, theme),
                );
              }),
            ),
            // 右栏：网格 + 课程卡片
            Expanded(
              child: SizedBox(
                height: rowHeight * displayPeriods,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellWidth = constraints.maxWidth / 7;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 底层：网格背景
                        _buildGridBackground(theme),
                        // 顶层：课程卡片
                        ..._buildCourseCards(theme, cellWidth),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 网格背景（仅 7×N 格线，不含课程内容）
  Widget _buildGridBackground(ThemeData theme) {
    return Column(
      children: List.generate(displayPeriods, (row) {
        return SizedBox(
          height: rowHeight,
          child: Row(
            children: List.generate(7, (col) {
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: theme.dividerColor.withOpacity(0.1),
                      ),
                      bottom: BorderSide(
                        color: theme.dividerColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  /// 所有课程卡片（绝对定位，不参与行内流）
  List<Widget> _buildCourseCards(ThemeData theme, double cellWidth) {
    final List<Widget> cards = [];

    for (final entry in coursesByDay.entries) {
      final day = entry.key;
      for (final course in entry.value) {
        if (course.startPeriod < startPeriod ||
            course.startPeriod >= startPeriod + displayPeriods) {
          continue;
        }

        final topOffset = (course.startPeriod - startPeriod) * rowHeight;
        final cardHeight = rowHeight * course.duration - 2;
        final leftOffset = (day - 1) * cellWidth;
        final cardWidth = cellWidth - 1; // 1px 间距
        final todoCount = todoCountMap[course.id] ?? 0;

        cards.add(
          Positioned(
            top: topOffset,
            left: leftOffset,
            width: cardWidth,
            height: cardHeight,
            child: CourseCard(
              course: course,
              incompleteTodoCount: todoCount,
              onTap: () => onCourseTap?.call(course),
              onLongPress: () => onCourseLongPress?.call(course),
            ),
          ),
        );
      }
    }

    return cards;
  }

  /// 节次标签（3 行：节次数、上课时间、下课时间）
  Widget _buildPeriodLabel(int period, ThemeData theme) {
    return Container(
      width: periodLabelWidth,
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
              color: theme.colorScheme.outline.withOpacity(0.6),
              fontSize: 8,
            ),
          ),
          Text(
            periodTimeMap[period]?.split(' - ').last ?? '',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline.withOpacity(0.35),
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }
}
