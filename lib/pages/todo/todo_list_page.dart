import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo_item.dart';
import '../../models/parsed_todo.dart';
import '../../models/course.dart';
import '../../providers/todo_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/speech_service.dart';
import '../../services/todo_parser_service.dart';
import '../../widgets/todo/todo_card_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../router/app_router.dart';
import '../../utils/app_strings.dart';

/// 待办列表页面
class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage>
    with SingleTickerProviderStateMixin {
  final SpeechService _speech = SpeechService();

  late AnimationController _pulseCtrl;
  StreamSubscription? _resultSub;
  bool _isVoiceRecording = false;
  String _recognizedText = '';

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
    _speech.reset();
    super.dispose();
  }

  // --- 语音录入 ---
  Future<void> _startVoiceRecording() async {
    final modelReady = await _speech.isModelReady();
    if (!mounted) return;
    if (!modelReady) {
      _showDownloadDialog();
      return;
    }

    setState(() {
      _isVoiceRecording = true;
      _recognizedText = '';
    });
    _pulseCtrl.repeat(reverse: true);

    _resultSub?.cancel();
    _resultSub = _speech.onResult.listen((result) {
      if (!mounted || !_isVoiceRecording) return;
      if (result.hasError) {
        if (result.error == 'MODEL_NOT_DOWNLOADED') {
          _showDownloadDialog();
          _stopPulse();
          setState(() => _isVoiceRecording = false);
        }
        return;
      }
      setState(() => _recognizedText = result.text ?? '');
    });

    try {
      await _speech.startListening();
    } catch (_) {
      if (mounted) {
        _stopPulse();
        setState(() => _isVoiceRecording = false);
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    _stopPulse();

    await _speech.stopListening();
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() => _isVoiceRecording = false);

    final text = _recognizedText.trim();
    if (text.isEmpty) return;

    final parsed = TodoParserService.parse(text);
    if (parsed.isEmpty) return;

    // 弹出预览编辑底部弹窗
    _showVoicePreview(parsed, text);
  }

  void _stopPulse() {
    _pulseCtrl.stop();
    _pulseCtrl.reset();
  }

  // --- 模型下载对话框 ---
  void _showDownloadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ModelDownloadDialog(speech: _speech),
    );
  }

  // --- 语音识别预览弹窗 ---
  void _showVoicePreview(List<ParsedTodo> todos, String rawText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _VoicePreviewSheet(
        todos: todos,
        rawText: rawText,
        onSave: () async {
          final notifier = ref.read(todoProvider.notifier);
          for (final pt in todos) {
            await notifier.addTodo(pt.toTodoItem());
          }
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.voiceSaved(todos.length))),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoState = ref.watch(todoProvider);
    final courseState = ref.watch(courseProvider);
    final theme = Theme.of(context);

    final filteredTodos = todoState.filteredTodos;

    final courseMap = <int, Course>{};
    for (final c in courseState.courses) {
      if (c.id != null) courseMap[c.id!] = c;
    }

    return Column(
      children: [
        // 筛选栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TodoFilter.values.map((filter) {
                final isSelected = todoState.filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(_filterLabel(filter)),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(todoProvider.notifier).setFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // 统计信息
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('共 ${filteredTodos.length} 项',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline)),
              if (todoState.filter == TodoFilter.all) ...[
                const SizedBox(width: 12),
                if (todoState.overdueCount > 0)
                  Text('${todoState.overdueCount} 项逾期',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.red)),
              ],
            ],
          ),
        ),

        // 语音录入状态条
        if (_isVoiceRecording)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.withValues(alpha: 0.08),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) =>
                      Transform.scale(scale: _pulseCtrl.value, child: child),
                  child: const Icon(Icons.mic, color: Colors.red, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _recognizedText.isNotEmpty ? _recognizedText : '正在聆听...',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.red),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // 待办列表
        Expanded(
          child: todoState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredTodos.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.task_alt,
                      title: _emptyTitle(todoState.filter),
                      subtitle: '点击下方按钮手动或语音添加',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      itemCount: filteredTodos.length,
                      itemBuilder: (context, index) {
                        final todo = filteredTodos[index];
                        Course? course;
                        String? courseName;
                        String? courseColor;
                        if (todo.courseId != null) {
                          course = courseMap[todo.courseId];
                          courseName = course?.name;
                          courseColor = course?.color;
                        }
                        return TodoCard(
                          todo: todo,
                          courseName: courseName,
                          courseColor: courseColor,
                          onTap: () =>
                              AppRouter.goTodoDetail(context, todo.id!),
                          onToggle: () => ref
                              .read(todoProvider.notifier)
                              .toggleComplete(todo.id!),
                          onDelete: () => _deleteTodo(context, ref, todo),
                        );
                      },
                    ),
        ),

        // 底部按钮：手动添加 + 语音（长按录音）
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => AppRouter.goTodoAdd(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(AppStrings.voiceAddManual,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(color: Colors.white)),
                        ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onLongPressStart: (_) => _startVoiceRecording(),
                  onLongPressEnd: (_) => _stopVoiceRecording(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isVoiceRecording
                          ? Colors.red
                          : theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isVoiceRecording ? Icons.mic : Icons.mic_none,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isVoiceRecording ? '松手识别' : AppStrings.voiceAddVoice,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 筛选 ---
  String _filterLabel(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return '全部';
      case TodoFilter.incomplete:
        return '未完成';
      case TodoFilter.completed:
        return '已完成';
      case TodoFilter.highPriority:
        return '高优先级';
      case TodoFilter.overdue:
        return '已逾期';
    }
  }

  String _emptyTitle(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return '还没有待办任务';
      case TodoFilter.incomplete:
        return '没有未完成任务';
      case TodoFilter.completed:
        return '没有已完成任务';
      case TodoFilter.highPriority:
        return '没有高优先级任务';
      case TodoFilter.overdue:
        return '没有逾期任务';
    }
  }

  Future<void> _deleteTodo(
      BuildContext context, WidgetRef ref, TodoItem todo) async {
    final ok = await ConfirmDialog.show(context,
      title: '删除待办',
      content: '确定删除「${todo.title}」？',
      confirmLabel: '删除',
      confirmColor: Colors.red,
    );
    if (ok == true) {
      await ref.read(todoProvider.notifier).deleteTodo(todo.id!);
    }
  }
}

// ============== 语音识别预览底部弹窗 ==============
class _VoicePreviewSheet extends StatefulWidget {
  final List<ParsedTodo> todos;
  final String rawText;
  final VoidCallback onSave;

  const _VoicePreviewSheet({
    required this.todos,
    required this.rawText,
    required this.onSave,
  });

  @override
  State<_VoicePreviewSheet> createState() => _VoicePreviewSheetState();
}

class _VoicePreviewSheetState extends State<_VoicePreviewSheet> {
  bool _saving = false;
  late List<ParsedTodo> _todos;

  @override
  void initState() {
    super.initState();
    _todos = widget.todos;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('识别结果（${_todos.length} 条）',
                        style: theme.textTheme.titleSmall),
                  ),
                  TextButton(
                    onPressed: () {
                      for (final pt in _todos) {
                        pt.title = '';
                        pt.priority = Priority.medium;
                        pt.dueDate = DateTime.now()
                            .toIso8601String()
                            .split('T')
                            .first;
                        pt.dueTime = null;
                      }
                      setState(() {});
                    },
                    child: const Text('丢弃'),
                  ),
                ],
              ),
            ),
            // 原始文本
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.rawText,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
            const SizedBox(height: 8),
            // 可编辑卡片列表
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: List.generate(_todos.length, (i) {
                    final todo = _todos[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('任务 ${i + 1}',
                                style: theme.textTheme.labelSmall),
                            TextField(
                              controller:
                                  TextEditingController(text: todo.title),
                              onChanged: (v) {
                                todo.title = v;
                                setState(() {});
                              },
                              decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                  isDense: true),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text('优先级  ',
                                    style: theme.textTheme.labelSmall),
                                SegmentedButton<int>(
                                  segments: const [
                                    ButtonSegment(
                                        value: 0, label: Text('紧急')),
                                    ButtonSegment(
                                        value: 1, label: Text('重要')),
                                    ButtonSegment(
                                        value: 2, label: Text('普通')),
                                  ],
                                  selected: {todo.priority.index},
                                  onSelectionChanged: (v) {
                                    todo.priority = Priority.values[v.first];
                                    setState(() {});
                                  },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    textStyle: WidgetStateProperty.all(
                                        theme.textTheme.labelSmall),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // 保存按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilledButton.icon(
                onPressed: _saving
                    ? null
                    : () {
                        setState(() => _saving = true);
                        widget.onSave();
                      },
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label:
                    Text(_saving ? '保存中...' : '全部保存 (${_todos.length} 条)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============== 模型下载对话框 ==============
class _ModelDownloadDialog extends StatefulWidget {
  final SpeechService speech;
  const _ModelDownloadDialog({required this.speech});

  @override
  State<_ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<_ModelDownloadDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.speech.modelDownloadProgress.listen((progress) {
      if (!mounted) return;
      if (progress >= 1.0) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _downloading = true;
          _progress = progress;
        });
      }
    }).onError((error) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = error.toString();
        });
      }
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    final ok = await widget.speech.downloadModel();
    if (!ok && mounted) {
      setState(() {
        _downloading = false;
        _error = AppStrings.modelDownloadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text(AppStrings.modelDownloadTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.modelDownloadDesc, style: theme.textTheme.bodyMedium),
          if (_downloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text(
              _progress > 0
                  ? '${(_progress * 100).toStringAsFixed(0)}%'
                  : AppStrings.modelDownloading,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style:
                    TextStyle(color: theme.colorScheme.error, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
        if (!_downloading)
          FilledButton(
            onPressed: _startDownload,
            child: const Text(AppStrings.modelDownloadStart),
          ),
      ],
    );
  }
}
