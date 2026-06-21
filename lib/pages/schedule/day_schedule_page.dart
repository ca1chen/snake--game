import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/semester_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/todo_provider.dart';
import '../../utils/date_utils.dart' as DateHelper;
import '../../utils/app_strings.dart';
import '../../utils/constants.dart';
import '../../models/semester.dart';
import '../../widgets/schedule/day_timeline_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../router/app_router.dart';
import '../../services/course_import_service.dart';

/// 日视图课程页面
class DaySchedulePage extends ConsumerStatefulWidget {
  final int? dayOfWeek;  // 从参数传入，nil=今天
  const DaySchedulePage({super.key, this.dayOfWeek});

  @override
  ConsumerState<DaySchedulePage> createState() => _DaySchedulePageState();
}

class _DaySchedulePageState extends ConsumerState<DaySchedulePage> {
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.dayOfWeek ?? DateTime.now().weekday;
  }

  @override
  Widget build(BuildContext context) {
    final semesterState = ref.watch(semesterProvider);
    final courseState = ref.watch(courseProvider);
    final todoState = ref.watch(todoProvider);

    final courses = courseState.coursesByDay[_selectedDay] ?? [];
    final semester = semesterState.currentSemester;
    final dateStr = semester != null
        ? DateHelper.DateUtils.getWeekStartDate(
            CourseImportService.estimateSemesterStart(semester.name),
            courseState.currentWeek,
          ).add(Duration(days: _selectedDay - 1))
        : DateTime.now();
    final dateLabel = DateHelper.DateUtils.formatDateCN(dateStr);

    // 课程-待办映射
    final todoCountMap = <int, int>{};
    for (final todo in todoState.todos) {
      if (todo.courseId != null && !todo.isCompleted) {
        todoCountMap[todo.courseId!] = (todoCountMap[todo.courseId!] ?? 0) + 1;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dateLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () => _pickDate(semester),
          ),
        ],
      ),
      body: Column(
        children: [
          // 星期选择器
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = day == _selectedDay;
                final isToday = DateTime.now().weekday == day;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: isSelected
                        ? BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.5,
                              ),
                            ),
                          )
                        : null,
                    child: Text(
                      weekdayLabels[day - 1],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isToday
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                                : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // 课程时间线
          Expanded(
            child: courses.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.event_busy,
                    title: AppStrings.scheduleEmptyDay,
                    subtitle: '换个日子看看？',
                  )
                : DayTimeline(
                    courses: courses,
                    dayOfWeek: _selectedDay,
                    dateLabel: dateLabel,
                    todoCountMap: todoCountMap,
                    onCourseTap: (course) {
                      AppRouter.goCourseDetail(context, course.id!);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(Semester? semester) async {
    if (semester == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: semester.startDate,
      lastDate: semester.endDate,
    );
    if (picked != null && mounted) {
      final effectiveStart = CourseImportService.estimateSemesterStart(semester.name);
      final week = DateHelper.DateUtils.getWeekNumber(effectiveStart, picked)
          .clamp(1, semester.totalWeeks);
      setState(() => _selectedDay = picked.weekday);
      ref.read(courseProvider.notifier).setWeek(week);
    }
  }
}
