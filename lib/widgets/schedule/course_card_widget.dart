import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../utils/constants.dart';

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

  Color get _color => parseHexColor(course.color);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 确保底色够深，白色文字始终可读（luminance > 0.5 时加深）
    Color bgColor = _color;
    if (bgColor.computeLuminance() > 0.5) {
      bgColor = Color.lerp(bgColor, const Color(0xFF333333), 0.35)!;
    }

    // 暗色模式：降低不透明度融入深色背景，文字稍柔和不刺眼
    final bgOpacity = isDark ? 0.55 : 0.85;
    final nameColor = isDark ? Colors.white.withOpacity(0.92) : Colors.white;
    final shadowOpacity = isDark ? 0.15 : 0.3;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(shadowOpacity),
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
                color: nameColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            // 教室（拆分为楼号 + 门牌号两行）
            if (course.classroom.isNotEmpty) ...[
              const SizedBox(height: 2),
              ..._buildClassroomLines(course.classroom, isDark: isDark),
            ],
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

  /// 将教室名拆分为楼号 + 门牌号两行
  /// "33楼204" → ["33楼", "204"]
  /// "教一楼A101" → ["教一楼", "A101"]
  /// 不含"楼"时尝试字母+数字结尾，都匹配不到则单行显示
  List<Widget> _buildClassroomLines(String classroom, {required bool isDark}) {
    String building;
    String room;

    // 优先按"楼"字分割（楼字归楼名）
    final louIdx = classroom.indexOf('楼');
    if (louIdx != -1) {
      building = classroom.substring(0, louIdx + 1);
      room = classroom.substring(louIdx + 1);
    } else {
      // 其次按"字母+数字结尾"分割
      final match = RegExp(r'^(.+?)([A-Za-z]+\d+)$').firstMatch(classroom);
      if (match != null) {
        building = match.group(1)!;
        room = match.group(2)!;
      } else {
        building = '';
        room = classroom;
      }
    }

    // 暗色模式：文字略灰，不刺眼
    final buildingOpacity = isDark ? 0.55 : 0.7;
    final roomOpacity = isDark ? 0.7 : 0.8;

    final lines = <Widget>[];
    if (building.isNotEmpty) {
      lines.add(Text(
        building,
        style: TextStyle(
          color: Colors.white.withOpacity(buildingOpacity),
          fontSize: 9,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ));
    }
    lines.add(Text(
      room,
      style: TextStyle(
        color: Colors.white.withOpacity(roomOpacity),
        fontSize: 9,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ));
    return lines;
  }
}
