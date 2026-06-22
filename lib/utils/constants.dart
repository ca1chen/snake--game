import 'package:flutter/painting.dart';

/// 节数时间段映射（天大作息）
const Map<int, String> periodTimeMap = {
  1: '08:30 - 09:15',
  2: '09:25 - 10:10',
  3: '10:30 - 11:15',
  4: '11:25 - 12:10',
  5: '14:00 - 14:45',
  6: '14:55 - 15:40',
  7: '16:00 - 16:45',
  8: '16:55 - 17:40',
  9: '18:30 - 19:15',
  10: '19:25 - 20:10',
  11: '20:20 - 21:05',
  12: '21:15 - 22:00',
};

/// 默认最大每天节数
const int defaultMaxPeriods = 12;

/// 默认显示节数（全天 12 节）
const int defaultDisplayPeriods = 12;

/// 课程卡片预设颜色列表（12色调，视觉差异最大化，均适配白字）
const List<String> courseColorPalette = [
  '#1565C0', // 蓝
  '#C62828', // 红
  '#2E7D32', // 绿
  '#EF6C00', // 橙
  '#6A1B9A', // 紫
  '#00695C', // 青
  '#4E342E', // 棕
  '#AD1457', // 粉
  '#37474F', // 蓝灰
  '#9E9D24', // 橄榄
  '#00838F', // 湖蓝
  '#BF360C', // 红棕
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

/// 离线语音识别 Paraformer 中文 Small 模型（HuggingFace 国内镜像）
const String sherpaOnnxModelUrl =
    'https://hf-mirror.com/csukuangfj/'
    'sherpa-onnx-paraformer-zh-small-2024-03-09/resolve/main/model.int8.onnx';

const String sherpaOnnxTokensUrl =
    'https://hf-mirror.com/csukuangfj/'
    'sherpa-onnx-paraformer-zh-small-2024-03-09/resolve/main/tokens.txt';

/// 模型存放子目录（相对于应用文档目录）
const String sherpaOnnxModelSubDir = 'sherpa_onnx/paraformer-zh-small';

/// 将 hex 颜色字符串解析为 Color
/// 支持格式: #RGB, #RRGGBB, RGB, RRGGBB (大小写不敏感)
/// 默认返回 #4A90D9（蓝色）
Color parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF4A90D9);
  var h = hex.replaceFirst('#', '');
  // 短格式 #RGB → #RRGGBB
  if (h.length == 3) {
    h = h.split('').map((c) => '$c$c').join();
  }
  if (h.length < 6) h = h.padRight(6, '0');
  final parsed = int.tryParse('FF${h.substring(0, 6)}', radix: 16);
  return parsed != null ? Color(parsed) : const Color(0xFF4A90D9);
}
