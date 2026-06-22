import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/parsed_todo.dart';
import '../../models/todo_item.dart';
import '../../providers/todo_provider.dart';
import '../../services/speech_service.dart';
import '../../services/todo_parser_service.dart';
import '../../widgets/common/model_download_dialog.dart';
import '../../utils/app_strings.dart';

/// 语音添加待办页面
class TodoVoiceAddPage extends ConsumerStatefulWidget {
  const TodoVoiceAddPage({super.key});

  @override
  ConsumerState<TodoVoiceAddPage> createState() => _TodoVoiceAddPageState();
}

enum _VoiceState { idle, listening, preview, saving }

class _TodoVoiceAddPageState extends ConsumerState<TodoVoiceAddPage>
    with SingleTickerProviderStateMixin {
  final SpeechService _speech = SpeechService();

  _VoiceState _state = _VoiceState.idle;
  String _rawText = '';
  String? _errorMsg;
  List<ParsedTodo> _parsedTodos = [];
  late AnimationController _pulseCtrl;
  StreamSubscription? _resultSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _pulseCtrl.dispose();
    _speech.reset(); // 仅重置录音状态，不关闭单例的 StreamController
    super.dispose();
  }

  // --- 录音 ---
  Future<void> _startRecording() async {
    // 检查模型是否已下载
    final modelReady = await _speech.isModelReady();
    if (!modelReady) {
      _showDownloadDialog();
      return;
    }

    setState(() {
      _state = _VoiceState.listening;
      _rawText = '';
      _errorMsg = null;
    });
    _pulseCtrl.repeat(reverse: true);

    // 先设置结果监听，再启动识别
    _resultSub?.cancel();
    _resultSub = _speech.onResult.listen((result) {
      if (result.hasError) {
        if (result.error == 'MODEL_NOT_DOWNLOADED') {
          if (mounted) _showDownloadDialog();
          if (mounted) setState(() => _state = _VoiceState.idle);
          _pulseCtrl.stop();
          return;
        }
        if (mounted) setState(() => _errorMsg = result.error);
        return;
      }
      if (mounted && _state == _VoiceState.listening) {
        setState(() => _rawText = result.text ?? '');
      }
    });

    try {
      await _speech.startListening();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = AppStrings.voiceStartFailed;
          _state = _VoiceState.idle;
        });
      }
      _pulseCtrl.stop();
    }
  }

  Future<void> _stopRecording() async {
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    await _speech.stopListening();
    // 等待识别结果回调
    await Future.delayed(const Duration(milliseconds: 400));

    if (_rawText.trim().isEmpty) {
      setState(() {
        _errorMsg = AppStrings.voiceNoContent;
        _state = _VoiceState.idle;
      });
      return;
    }

    setState(() {
      _parsedTodos = TodoParserService.parse(_rawText);
      _state = _parsedTodos.isEmpty ? _VoiceState.idle : _VoiceState.preview;
      if (_parsedTodos.isEmpty) {
        _errorMsg = AppStrings.voiceNoTask;
      } else {
        _errorMsg = null;
      }
    });
  }

  // --- 模型下载对话框 ---
  void _showDownloadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ModelDownloadDialog(speech: _speech),
    );
  }

  // --- 保存 ---
  Future<void> _saveAll() async {
    setState(() => _state = _VoiceState.saving);
    final notifier = ref.read(todoProvider.notifier);
    for (final pt in _parsedTodos) {
      await notifier.addTodo(pt.toTodoItem());
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.voiceSaved(_parsedTodos.length))),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.voiceAddTitle),
        actions: [
          if (_state == _VoiceState.preview)
            TextButton(
              onPressed: () {
                setState(() {
                  _state = _VoiceState.idle;
                  _rawText = '';
                  _parsedTodos = [];
                  _errorMsg = null;
                });
              },
              child: const Text(AppStrings.voiceRetry),
            ),
        ],
      ),
      body: _buildBody(theme),
      bottomNavigationBar: _buildBottom(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_state) {
      case _VoiceState.idle:
      case _VoiceState.listening:
        return _buildMicArea(theme);
      case _VoiceState.preview:
        return _buildPreview(theme);
      case _VoiceState.saving:
        return const Center(child: CircularProgressIndicator());
    }
  }

  // --- 麦克风 + 提示（idle 和 listening 共用同一个 GestureDetector） ---
  Widget _buildMicArea(ThemeData theme) {
    final isListening = _state == _VoiceState.listening;
    final micColor = isListening ? Colors.red : theme.colorScheme.primary;
    final bgColor = micColor.withValues(alpha: 0.12);
    final hintText = isListening ? AppStrings.voiceListening : AppStrings.voiceHint;

    // 容器（不含 GestureDetector，避免动画重建破坏手势）
    Widget micContainer = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Icon(Icons.mic, size: 48, color: micColor),
    );

    // 录音中加脉冲动画，但 GestureDetector 始终在最外层
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecording(),
          child: isListening
              ? AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) =>
                      Transform.scale(scale: _pulseCtrl.value, child: child),
                  child: micContainer,
                )
              : micContainer,
        ),
        const SizedBox(height: 20),
        Text(hintText, style: theme.textTheme.bodyMedium),
        if (isListening && _rawText.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _rawText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
        if (_errorMsg != null) ...[
          const SizedBox(height: 12),
          Text(_errorMsg!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ]),
    );
  }

  // --- 预览状态 ---
  Widget _buildPreview(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 原始文本
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppStrings.voiceRecognizedText, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(_rawText, style: theme.textTheme.bodyMedium),
          ]),
        ),
        const SizedBox(height: 16),

        // 待办卡片列表
        ...List.generate(_parsedTodos.length, (i) {
          return _TodoEditCard(
            todo: _parsedTodos[i],
            onChanged: (updated) {
              setState(() => _parsedTodos[i] = updated);
            },
          );
        }),
      ]),
    );
  }

  Widget? _buildBottom(ThemeData theme) {
    if (_state != _VoiceState.preview) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _parsedTodos.isEmpty ? null : _saveAll,
            icon: const Icon(Icons.save),
            label: Text(AppStrings.voiceSaveAll(_parsedTodos.length)),
          ),
        ),
      ),
    );
  }
}

/// 可编辑的待办卡片
class _TodoEditCard extends StatelessWidget {
  final ParsedTodo todo;
  final ValueChanged<ParsedTodo> onChanged;

  const _TodoEditCard({required this.todo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 标题
          Text('任务 ${todo.index + 1}', style: theme.textTheme.labelSmall),
          TextField(
            controller: TextEditingController(text: todo.title),
            onChanged: (v) {
              todo.title = v;
              onChanged(todo);
            },
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // 优先级
          Row(children: [
            Text('优先级  ', style: theme.textTheme.labelSmall),
            const SizedBox(width: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('紧急')),
                ButtonSegment(value: 1, label: Text('重要')),
                ButtonSegment(value: 2, label: Text('普通')),
              ],
              selected: {todo.priority.index},
              onSelectionChanged: (v) {
                todo.priority = Priority.values[v.first];
                onChanged(todo);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(theme.textTheme.labelSmall),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // 日期 + 时间
          Row(children: [
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(todo.dueDate),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(todo.dueDate) ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  todo.dueDate =
                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  onChanged(todo);
                }
              },
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.access_time, size: 16),
              label: Text(todo.dueTime ?? '无时间'),
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  todo.dueTime =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  onChanged(todo);
                }
              },
            ),
            if (todo.dueTime != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  todo.dueTime = null;
                  onChanged(todo);
                },
                visualDensity: VisualDensity.compact,
              ),
          ]),
        ]),
      ),
    );
  }
}

/// 模型下载对话框
