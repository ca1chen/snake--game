import '../models/semester.dart';
import '../models/course.dart';
import '../repositories/semester_repository.dart';
import '../repositories/course_repository.dart';
import '../services/course_import_service.dart';

/// 天大（TJU）2025-2026学年第二学期种子课程数据
///
/// 仅在首次启动且数据库无学期数据时自动导入。
/// 后续启动会自动跳过（检测到已有学期数据）。
Future<void> seedTJUCoursesIfEmpty() async {
  final semRepo = SemesterRepository();
  final courseRepo = CourseRepository();

  final existingSemesters = await semRepo.getAll();
  if (existingSemesters.isNotEmpty) return; // 已有数据，跳过

  // 创建学期（使用天大校历开学日期）
  const semesterName = '2025-2026学年第二学期';
  final startDate = CourseImportService.estimateSemesterStart(semesterName);
  final semester = Semester(
    name: semesterName,
    startDate: startDate,
    endDate: startDate.add(const Duration(days: 18 * 7 - 1)),
    totalWeeks: 18,
    isCurrent: true,
  );
  final semesterId = await semRepo.insert(semester);

  // 课程数据
  final courses = <Course>[
    // 周一 1-2节
    Course(semesterId: semesterId, name: '微积分II', teacher: '尚英锋', classroom: '45楼B307', dayOfWeek: 1, startPeriod: 1, duration: 2, startWeek: 1, endWeek: 14, weekType: WeekType.every, color: '#FF6B6B'),
    Course(semesterId: semesterId, name: '中国近现代史纲要', teacher: '黎博雅', classroom: '45楼B211', dayOfWeek: 1, startPeriod: 3, duration: 2, startWeek: 1, endWeek: 15, weekType: WeekType.odd, color: '#96CEB4'),
    Course(semesterId: semesterId, name: '大学物理2A', teacher: '肖立峰', classroom: '33楼204', dayOfWeek: 1, startPeriod: 5, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#45B7D1'),
    Course(semesterId: semesterId, name: '理论力学3', teacher: '钟顺', classroom: '37楼511', dayOfWeek: 1, startPeriod: 7, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#F7DC6F'),
    // 周二 1-2节
    Course(semesterId: semesterId, name: '工程图学3A', teacher: '景秀并', classroom: '33楼109', dayOfWeek: 2, startPeriod: 1, duration: 2, startWeek: 4, endWeek: 15, weekType: WeekType.every, color: '#4ECDC4'),
    // 周二 3-4节
    Course(semesterId: semesterId, name: '工程图学3A', teacher: '景秀并', classroom: '33楼109', dayOfWeek: 2, startPeriod: 3, duration: 2, startWeek: 4, endWeek: 15, weekType: WeekType.every, color: '#4ECDC4'),
    // 周二 5-6节
    Course(semesterId: semesterId, name: '翻译与跨文化传播', teacher: '张宇', classroom: '46楼A107', dayOfWeek: 2, startPeriod: 5, duration: 2, startWeek: 1, endWeek: 15, weekType: WeekType.odd, color: '#98D8C8'),
    // 周二 7-8节
    Course(semesterId: semesterId, name: '英语交流与沟通', teacher: '张文真', classroom: '46楼A209', dayOfWeek: 2, startPeriod: 7, duration: 2, startWeek: 2, endWeek: 16, weekType: WeekType.even, color: '#85C1E9'),
    // 周二 9-10节 (前8周)
    Course(semesterId: semesterId, name: '职业生涯规划', teacher: '艾丽皮热·衣沙克', classroom: '45楼B115', dayOfWeek: 2, startPeriod: 9, duration: 2, startWeek: 1, endWeek: 8, weekType: WeekType.every, color: '#A3E4D7'),
    // 周二 9-10节 (后8周)
    Course(semesterId: semesterId, name: '大学生心理健康（下）', teacher: '刘新春', classroom: '45楼B115', dayOfWeek: 2, startPeriod: 9, duration: 2, startWeek: 9, endWeek: 16, weekType: WeekType.every, color: '#AED6F1'),
    // 周三 1-2节
    Course(semesterId: semesterId, name: '微积分II', teacher: '尚英锋', classroom: '45楼B307', dayOfWeek: 3, startPeriod: 1, duration: 2, startWeek: 1, endWeek: 14, weekType: WeekType.every, color: '#FF6B6B'),
    // 周三 3-4节
    Course(semesterId: semesterId, name: '中国近现代史纲要', teacher: '黎博雅', classroom: '45楼B211', dayOfWeek: 3, startPeriod: 3, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#96CEB4'),
    // 周三 5-6节
    Course(semesterId: semesterId, name: '理论力学3', teacher: '钟顺', classroom: '37楼511', dayOfWeek: 3, startPeriod: 5, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#F7DC6F'),
    // 周三 7-8节
    Course(semesterId: semesterId, name: '线性代数初步', teacher: '张颖', classroom: '45楼B109', dayOfWeek: 3, startPeriod: 7, duration: 2, startWeek: 1, endWeek: 12, weekType: WeekType.every, color: '#DDA0DD'),
    // 周三 9-10节
    Course(semesterId: semesterId, name: '大学化学1', teacher: '马亚鲁', classroom: '46楼A205', dayOfWeek: 3, startPeriod: 9, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#82E0AA'),
    // 周四 1-2节
    Course(semesterId: semesterId, name: '大学物理2A', teacher: '肖立峰', classroom: '33楼204', dayOfWeek: 4, startPeriod: 1, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#45B7D1'),
    // 周四 3-4节
    Course(semesterId: semesterId, name: '体育B', teacher: '杨玉明', classroom: '', dayOfWeek: 4, startPeriod: 3, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#FFEAA7'),
    // 周四 7-8节
    Course(semesterId: semesterId, name: '工程图学3A', teacher: '景秀并', classroom: '33楼109', dayOfWeek: 4, startPeriod: 7, duration: 2, startWeek: 4, endWeek: 15, weekType: WeekType.every, color: '#4ECDC4'),
    // 周四 9-10节
    Course(semesterId: semesterId, name: '学科前沿导论与认知实习', teacher: '刘海涛', classroom: '46楼A110', dayOfWeek: 4, startPeriod: 9, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#F8C471'),
    // 周五 1-2节
    Course(semesterId: semesterId, name: '微积分II', teacher: '尚英锋', classroom: '45楼B307', dayOfWeek: 5, startPeriod: 1, duration: 2, startWeek: 1, endWeek: 14, weekType: WeekType.every, color: '#FF6B6B'),
    // 周五 3-4节
    Course(semesterId: semesterId, name: '线性代数初步', teacher: '张颖', classroom: '45楼B109', dayOfWeek: 5, startPeriod: 3, duration: 2, startWeek: 1, endWeek: 12, weekType: WeekType.every, color: '#DDA0DD'),
    // 周五 5-6节
    Course(semesterId: semesterId, name: '国家安全教育', teacher: '王茜', classroom: '45楼B201', dayOfWeek: 5, startPeriod: 5, duration: 2, startWeek: 1, endWeek: 4, weekType: WeekType.every, color: '#BB8FCE'),
    // 周五 9-10节
    Course(semesterId: semesterId, name: '军事理论1', teacher: '朱丙锋', classroom: '33楼113', dayOfWeek: 5, startPeriod: 9, duration: 2, startWeek: 1, endWeek: 16, weekType: WeekType.every, color: '#D7BDE2', notes: '第7周在线教学'),
    // 周日 3-4节 (工程图学实验)
    Course(semesterId: semesterId, name: '工程图学3A', teacher: '景秀并', classroom: '33楼108', dayOfWeek: 7, startPeriod: 3, duration: 2, startWeek: 12, endWeek: 12, weekType: WeekType.every, color: '#4ECDC4'),
  ];

  for (final course in courses) {
    await courseRepo.insert(course);
  }
}
