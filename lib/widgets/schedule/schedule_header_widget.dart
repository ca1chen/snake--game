import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart' as DateHelper;
import '../../utils/app_strings.dart';
import '../../models/semester.dart';

/// 周视图表头组件：周次切换 + 日期显示
class ScheduleHeader extends StatelessWidget {
  final Semester? currentSemester;
  final int currentWeek;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onTapToday;
  final VoidCallback? onTapDayView;

  const ScheduleHeader({
    super.key,
    required this.currentSemester,
    required this.currentWeek,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onTapToday,
    this.onTapDayView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // 周次切换栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 学期名
              Text(
                currentSemester?.name ?? '未设置学期',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              // 周次导航
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    onPressed: onPrevWeek,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  GestureDetector(
                    onTap: onTapToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '第 $currentWeek 周',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    onPressed: onNextWeek,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              // 日视图切换按钮
              IconButton(
                icon: const Icon(Icons.view_agenda, size: 22),
                onPressed: onTapDayView,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: AppStrings.scheduleDayView,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 日期行（周一 ～ 周日）
          if (currentSemester != null)
            Row(
              children: List.generate(7, (index) {
                final day = index + 1; // 1=周一
                final date = DateHelper.DateUtils.getWeekStartDate(
                  currentSemester!.startDate,
                  currentWeek,
                ).add(Duration(days: index));
                final isToday = DateHelper.DateUtils.isSameDay(date, DateTime.now());

                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: isToday
                        ? BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Column(
                      children: [
                        Text(
                          weekdayLabels[day - 1],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${date.month}/${date.day}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                            color: isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
