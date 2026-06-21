import 'package:flutter/material.dart';
import '../../models/course.dart';

/// 课程卡片组件（显示在周视图网格中）
class CourseCard extends StatelessWidget {
  final Course course;
  final int incompleteTodoCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CourseCard({
    super.key,
    required this.course,
    this.incompleteTodoCount = 0,
    this.onTap,
    this.onLongPress,
  });

  Color get _color {
    final hex = course.color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: _color.withOpacity(isLight ? 0.88 : 0.7),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: _color.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 课程名
            Text(
              course.name,
              style: TextStyle(
                color: isLight ? Colors.white : Colors.white.withOpacity(0.95),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // 教室
            if (course.classroom.isNotEmpty)
              Text(
                course.classroom,
                style: TextStyle(
                  color: (isLight ? Colors.white : Colors.white).withOpacity(0.8),
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // 待办角标
            if (incompleteTodoCount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$incompleteTodoCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
