import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/course.dart';
import '../../providers/semester_provider.dart';
import '../../providers/course_provider.dart';
import '../../utils/constants.dart';

/// 课程编辑页面（添加/编辑）
class CourseEditPage extends ConsumerStatefulWidget {
  final Course? course; // null = 添加模式
  final int? defaultSemesterId;

  const CourseEditPage({super.key, this.course, this.defaultSemesterId});

  @override
  ConsumerState<CourseEditPage> createState() => _CourseEditPageState();
}

class _CourseEditPageState extends ConsumerState<CourseEditPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _teacherCtrl;
  late TextEditingController _classroomCtrl;
  late TextEditingController _notesCtrl;

  late int _dayOfWeek;
  late int _startPeriod;
  late int _duration;
  late int _startWeek;
  late int _endWeek;
  late WeekType _weekType;
  late String _color;
  late int _semesterId;

  bool get isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _teacherCtrl = TextEditingController(text: c?.teacher ?? '');
    _classroomCtrl = TextEditingController(text: c?.classroom ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _dayOfWeek = c?.dayOfWeek ?? DateTime.now().weekday;
    _startPeriod = c?.startPeriod ?? 1;
    _duration = c?.duration ?? 2;
    _startWeek = c?.startWeek ?? 1;
    _endWeek = c?.endWeek ?? 18;
    _weekType = c?.weekType ?? WeekType.every;
    _color = c?.color ?? courseColorPalette[0];
    _semesterId = c?.semesterId ?? widget.defaultSemesterId ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teacherCtrl.dispose();
    _classroomCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入课程名称')),
      );
      return;
    }
    if (_semesterId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先设置当前学期')),
      );
      return;
    }

    final course = Course(
      id: widget.course?.id,
      semesterId: _semesterId,
      name: _nameCtrl.text.trim(),
      teacher: _teacherCtrl.text.trim(),
      classroom: _classroomCtrl.text.trim(),
      dayOfWeek: _dayOfWeek,
      startPeriod: _startPeriod,
      duration: _duration,
      startWeek: _startWeek,
      endWeek: _endWeek,
      weekType: _weekType,
      color: _color,
      notes: _notesCtrl.text.trim(),
    );

    if (isEditing) {
      await ref.read(courseProvider.notifier).updateCourse(course);
    } else {
      await ref.read(courseProvider.notifier).addCourse(course);
    }

    // 检查是否保存成功
    if (!mounted) return;
    final error = ref.read(courseProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $error'), backgroundColor: Colors.red),
      );
      ref.read(courseProvider.notifier).clearError();
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final semesterState = ref.watch(semesterProvider);
    final theme = Theme.of(context);

    // 监听学期加载完成，自动设置当前学期
    ref.listen(semesterProvider, (prev, next) {
      final semesterId = next.currentSemester?.id;
      if (_semesterId == 0 && semesterId != null) {
        setState(() => _semesterId = semesterId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑课程' : '添加课程'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息
            _sectionTitle(theme, '基本信息'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '课程名称', hintText: '高等数学A(一)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _teacherCtrl, decoration: const InputDecoration(labelText: '教师', hintText: '张三'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _classroomCtrl, decoration: const InputDecoration(labelText: '教室', hintText: '教一楼A101'))),
              ],
            ),

            const SizedBox(height: 20),
            _sectionTitle(theme, '时间安排'),
            const SizedBox(height: 8),

            // 星期几
            _dropdownRow(
              label: '上课日期',
              value: weekdayLabels[_dayOfWeek - 1],
              items: List.generate(7, (i) => weekdayLabels[i]),
              onChanged: (v) {
                setState(() => _dayOfWeek = weekdayLabels.indexOf(v!) + 1);
              },
            ),
            const SizedBox(height: 10),

            // 起始节数 + 持续节数
            Row(
              children: [
                Expanded(
                  child: _dropdownRow(
                    label: '起始节',
                    value: '第 $_startPeriod 节',
                    items: List.generate(12, (i) => '第 ${i + 1} 节'),
                    onChanged: (v) {
                      setState(() => _startPeriod = int.parse(v!.replaceAll(RegExp(r'[^0-9]'), '')));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdownRow(
                    label: '持续',
                    value: '$_duration 节',
                    items: const ['1 节', '2 节', '3 节', '4 节'],
                    onChanged: (v) {
                      setState(() => _duration = int.parse(v!.replaceAll(RegExp(r'[^0-9]'), '')));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 周次范围
            Row(
              children: [
                Expanded(
                  child: _dropdownRow(
                    label: '起始周',
                    value: '第 $_startWeek 周',
                    items: List.generate(20, (i) => '第 ${i + 1} 周'),
                    onChanged: (v) {
                      final w = int.parse(v!.replaceAll(RegExp(r'[^0-9]'), ''));
                      setState(() {
                        _startWeek = w;
                        if (_endWeek < w) _endWeek = w;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdownRow(
                    label: '结束周',
                    value: '第 $_endWeek 周',
                    items: List.generate(20, (i) => '第 ${i + 1} 周'),
                    onChanged: (v) {
                      setState(() => _endWeek = int.parse(v!.replaceAll(RegExp(r'[^0-9]'), '')));
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _sectionTitle(theme, '周次类型'),
            const SizedBox(height: 8),
            SegmentedButton<WeekType>(
              segments: const [
                ButtonSegment(value: WeekType.every, label: Text('每周')),
                ButtonSegment(value: WeekType.odd, label: Text('单周')),
                ButtonSegment(value: WeekType.even, label: Text('双周')),
              ],
              selected: {_weekType},
              onSelectionChanged: (s) => setState(() => _weekType = s.first),
            ),

            const SizedBox(height: 20),
            _sectionTitle(theme, '颜色'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: courseColorPalette.map((hex) {
                final color = parseHexColor(hex);
                final isSelected = hex == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 3) : null,
                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)] : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            _sectionTitle(theme, '备注'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(hintText: '教材、网站链接等'),
              maxLines: 2,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('保存课程')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700));
  }

  Widget _dropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        ),
      ],
    );
  }
}

extension _WeekTypeExt on WeekType {
  String get label {
    switch (this) {
      case WeekType.every: return '每周';
      case WeekType.odd: return '单周';
      case WeekType.even: return '双周';
    }
  }
}
