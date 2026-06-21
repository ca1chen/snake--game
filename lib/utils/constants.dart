/// 节数时间段映射
/// 高校典型作息: 第1节 08:00-08:45, 第2节 08:55-09:40, ...
const Map<int, String> periodTimeMap = {
  1: '08:00 - 08:45',
  2: '08:55 - 09:40',
  3: '10:00 - 10:45',
  4: '10:55 - 11:40',
  5: '14:00 - 14:45',
  6: '14:55 - 15:40',
  7: '16:00 - 16:45',
  8: '16:55 - 17:40',
  9: '19:00 - 19:45',
  10: '19:55 - 20:40',
  11: '20:50 - 21:35',
  12: '21:45 - 22:30',
};

/// 默认最大每天节数
const int defaultMaxPeriods = 12;

/// 默认显示节数（常规 5 节/天）
const int defaultDisplayPeriods = 6;

/// 课程卡片预设颜色列表
const List<String> courseColorPalette = [
  '#4A90D9', // 蓝
  '#E74C3C', // 红
  '#2ECC71', // 绿
  '#F39C12', // 橙
  '#9B59B6', // 紫
  '#1ABC9C', // 青
  '#E67E22', // 深橙
  '#3498DB', // 天蓝
  '#E91E63', // 粉
  '#00BCD4', // 湖蓝
  '#FF5722', // 深红
  '#8BC34A', // 浅绿
];

/// 优先级颜色映射
const Map<int, int> priorityColorMap = {
  0: 0xFF9E9E9E, // 低 - 灰
  1: 0xFFFFA726, // 中 - 橙
  2: 0xFFEF5350, // 高 - 红
};

/// 优先级文字映射
const Map<int, String> priorityLabelMap = {
  0: '低',
  1: '中',
  2: '高',
};

/// 星期标签
const List<String> weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// 数据库名称
const String dbName = 'firstcc.db';

/// 数据库版本
const int dbVersion = 1;
