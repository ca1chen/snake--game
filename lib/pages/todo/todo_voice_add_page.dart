import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/parsed_todo.dart';
import '../../models/todo_item.dart';
import '../../providers/todo_provider.dart';
import '../../services/speech_service.dart';
import '../../services/todo_parser_service.dart';

/// 语音添加待办 — 通过底部弹出面板交互
/// 调用方式：
///   TodoVoiceAddPage.show(context)             — 完整流程（idle→录音→预览）
///   TodoVoiceAddPage.showPreview(ctx, text, list) — 直接进入预览编辑
class TodoVoiceAddPage extends ConsumerStatefulWidget {
  final bool startInPreview;
  final String initialText;
  final List<ParsedTodo> initialParsed;

  const TodoVoiceAddPage({
    super.key,
    this.startInPreview = false,
    this.initialText = '',
    this.initialParsed = const [],
  });

  /// 以底部弹出面板形式展示语音添加（完整流程）
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const TodoVoiceAddPage(),
    );
  }

  /// 直接进入预览模式（外部已录音+解析完毕）
  static Future<void> showPreview(
    BuildContext context,
    String recognizedText,
    List<ParsedTodo> parsed,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TodoVoiceAddPage(
        startInPreview: true,
        initialText: recognizedText,
        initialParsed: parsed,
      ),
    );
  }

  @override
  ConsumerState<TodoVoiceAddPage> createState() => _TodoVoiceAddPageState();
}

enum _VoiceState { idle, listening, preview, saving }

class _TodoVoiceAddPageState extends ConsumerState<TodoVoiceAddPage>
    with TickerProviderStateMixin {
  _VoiceState _voiceState = _VoiceState.idle;
  String _recognizedText = '';
  String _partialText = '';

  List<ParsedTodo> _parsedTodos = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _speechReady = false;

  final Map<int, TextEditingController> _titleControllers = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 如果外部已录音并解析好，直接进入预览
    if (widget.startInPreview) {
      _voiceState = _VoiceState.preview;
      _recognizedText = widget.initialText;
      _parsedTodos = widget.initialParsed;
      for (final item in _parsedTodos) {
        _titleControllers[item.index] = TextEditingController(text: item.title);
      }
    } else {
      _initSpeech();
    }
  }

  @override
  void dispose() {
    for (final c in _titleControllers.values) { c.dispose(); }
    _pulseController.dispose();
    SpeechService.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechReady = await SpeechService.initialize();
    if (mounted) setState(() {});
  }

  // --- 录音 ---

  Future<void> _startRecording() async {
    if (!_speechReady) {
      _speechReady = await SpeechService.initialize();
      if (!_speechReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('麦克风不可用，请在系统设置中授权后重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _voiceState = _VoiceState.listening;
      _recognizedText = '';
      _partialText = '';
    });

    _pulseController.repeat(reverse: true);
    await SpeechService.startListening(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            if (isFinal) {
              _recognizedText = text;
              _partialText = '';
            } else {
              _partialText = text;
            }
          });
        }
      },
    );
  }

  Future<void> _stopRecording() async {
    _pulseController.stop();
    _pulseController.reset();

    final finalText = await SpeechService.stopListening();
    if (!mounted) return;

    final text = finalText.isNotEmpty ? finalText : _recognizedText;
    setState(() {
      _recognizedText = text;
      _partialText = '';
    });

    if (text.trim().isEmpty) {
      _showNoContent();
    } else {
      _parseAndShow(text);
    }
  }

  void _parseAndShow(String rawText) {
    final parsed = TodoParserService.parse(rawText);
    setState(() {
      _parsedTodos = parsed;
      for (final c in _titleControllers.values) { c.dispose(); }
      _titleControllers.clear();
      for (final item in _parsedTodos) {
        _titleControllers[item.index] = TextEditingController(text: item.title);
      }
      _voiceState = _VoiceState.preview;
    });

    if (_parsedTodos.isEmpty) _showNoContent();
  }

  void _showNoContent() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.mic_off, size: 40, color: Colors.orange),
        title: const Text('未检测到任务内容'),
        content: const Text('语音识别为空或无法解析，请重新录音。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reset();
            },
            child: const Text('重新录音'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _voiceState = _VoiceState.idle;
      _recognizedText = '';
      _partialText = '';
      _parsedTodos = [];
      for (final c in _titleControllers.values) { c.dispose(); }
      _titleControllers.clear();
    });
  }

  // --- 保存 ---

  Future<void> _saveAll() async {
    for (final item in _parsedTodos) {
      final ctrl = _titleControllers[item.index];
      if (ctrl != null) item.title = ctrl.text.trim();
    }

    final validTodos = _parsedTodos.where((p) => p.title.isNotEmpty).toList();
    if (validTodos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有有效任务内容')),
      );
      return;
    }

    setState(() => _voiceState = _VoiceState.saving);

    try {
      final notifier = ref.read(todoProvider.notifier);
      for (final parsed in validTodos) {
        await notifier.addTodo(parsed.toTodoItem());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已保存 ${validTodos.length} 条待办'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _voiceState = _VoiceState.preview);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 单条编辑 ---

  Future<void> _pickDate(int index) async {
    final current = _parsedTodos[index];
    final initial = DateTime.tryParse(current.dueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _parsedTodos[index].dueDate = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _pickTime(int index) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      setState(() {
        _parsedTodos[index].dueTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: _voiceState == _VoiceState.idle || _voiceState == _VoiceState.listening
          ? 340
          : MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // 顶部拖拽条
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // 主体
          Expanded(child: _buildBody(theme)),
          // 底部按钮
          if (_voiceState == _VoiceState.preview && _parsedTodos.isNotEmpty)
            _buildBottomBar(theme),
          SizedBox(height: bottomInset > 0 ? bottomInset : 8),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_voiceState) {
      case _VoiceState.idle:
        return _buildIdle(theme);
      case _VoiceState.listening:
        return _buildListening(theme);
      case _VoiceState.preview:
        return _buildPreview(theme);
      case _VoiceState.saving:
        return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(), SizedBox(height: 12), Text('正在保存...'),
        ]));
    }
  }

  Widget _buildIdle(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMicButton(),
          const SizedBox(height: 20),
          Text('长按麦克风开始录音', style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          )),
        ],
      ),
    );
  }

  Widget _buildListening(ThemeData theme) {
    return Column(
      children: [
        const Spacer(flex: 2),
        _buildMicButton(),
        const SizedBox(height: 24),
        if (_partialText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_partialText, textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)),
            ),
          ),
        const Spacer(flex: 1),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text('松开停止', style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.shade400)),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    if (_parsedTodos.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text('未检测到任务', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _reset, icon: const Icon(Icons.mic, size: 18), label: const Text('重新录音')),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_recognizedText.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_recognizedText, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55), fontStyle: FontStyle.italic,
            )),
          ),
          const SizedBox(height: 12),
        ],
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('解析出 ${_parsedTodos.length} 条待办', style: theme.textTheme.titleSmall),
          TextButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh, size: 16), label: const Text('重录')),
        ]),
        const SizedBox(height: 8),
        ..._parsedTodos.map((item) => _buildCard(item, theme)),
      ]),
    );
  }

  Widget _buildCard(ParsedTodo item, ThemeData theme) {
    final cs = _pColor(item.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: cs.bg, borderRadius: BorderRadius.circular(4)),
              child: Text('${item.index + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.fg)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: cs.fg.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(_pName(item.priority), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.fg)),
            ),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _titleControllers[item.index],
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9)),
            style: theme.textTheme.bodyMedium,
            onChanged: (v) => item.title = v.trim(),
          ),
          const SizedBox(height: 8),
          SegmentedButton<Priority>(
            segments: const [
              ButtonSegment(value: Priority.low, label: Text('低', style: TextStyle(fontSize: 11))),
              ButtonSegment(value: Priority.medium, label: Text('中', style: TextStyle(fontSize: 11))),
              ButtonSegment(value: Priority.high, label: Text('高', style: TextStyle(fontSize: 11))),
            ],
            selected: {item.priority},
            onSelectionChanged: (s) => setState(() => item.priority = s.first),
            style: ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: InkWell(
              onTap: () => _pickDate(item.index),
              borderRadius: BorderRadius.circular(6),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2), child: Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(_fmtDate(item.dueDate), style: theme.textTheme.bodySmall),
              ])),
            )),
            InkWell(
              onTap: () => _pickTime(item.index),
              borderRadius: BorderRadius.circular(6),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2), child: Row(children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(item.dueTime ?? '时间', style: theme.textTheme.bodySmall?.copyWith(
                  color: item.dueTime != null ? null : Colors.grey)),
                if (item.dueTime != null) ...[
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () => setState(() => item.dueTime = null),
                    child: const Icon(Icons.close, size: 12, color: Colors.grey),
                  ),
                ],
              ])),
            ),
          ]),
          if (item.rawText.isNotEmpty)
            Text('"${item.rawText}"', style: TextStyle(fontSize: 10,
              color: theme.colorScheme.onSurface.withOpacity(0.3), fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: theme.colorScheme.surface, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, -2)),
      ]),
      child: SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: _voiceState == _VoiceState.saving ? null : _saveAll,
        icon: const Icon(Icons.save_alt, size: 18),
        label: Text('全部保存 (${_parsedTodos.length})'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
      )),
    );
  }

  // --- 麦克风按钮 ---

  Widget _buildMicButton() {
    final isListening = _voiceState == _VoiceState.listening;
    final color = isListening ? Colors.red : const Color(0xFF4A90D9);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressCancel: () => _stopRecording(),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isListening ? _pulseAnimation.value : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 18, spreadRadius: 3)],
          ),
          child: const Center(
            child: Icon(Icons.mic, size: 38, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // --- 辅助 ---

  _PriorityColor _pColor(Priority p) {
    switch (p) {
      case Priority.high: return _PriorityColor(Colors.red.shade50, Colors.red);
      case Priority.medium: return _PriorityColor(Colors.orange.shade50, Colors.orange);
      case Priority.low: return _PriorityColor(Colors.grey.shade200, Colors.grey.shade700);
    }
  }

  String _pName(Priority p) {
    switch (p) {
      case Priority.high: return '紧急';
      case Priority.medium: return '重要';
      case Priority.low: return '普通';
    }
  }

  String _fmtDate(String ds) {
    final d = DateTime.tryParse(ds);
    if (d == null) return ds;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == 2) return '后天';
    const wd = ['周一','周二','周三','周四','周五','周六','周日'];
    return '${d.month}月${d.day}日 ${wd[d.weekday - 1]}';
  }
}

class _PriorityColor {
  final Color bg, fg;
  _PriorityColor(this.bg, this.fg);
}
