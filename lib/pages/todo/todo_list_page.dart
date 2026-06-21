import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/todo_item.dart';
import '../../models/course.dart';
import '../../models/parsed_todo.dart';
import '../../providers/todo_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/speech_service.dart';
import '../../services/todo_parser_service.dart';
import '../../widgets/todo/todo_card_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../../router/app_router.dart';
import 'todo_voice_add_page.dart';

/// 待办列表页面
class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage>
    with TickerProviderStateMixin {
  bool _speechReady = false;
  bool _isRecording = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    SpeechService.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechReady = await SpeechService.initialize();
    if (mounted) setState(() {});
  }

  // --- 长按录音 ---

  Future<void> _startRecording() async {
    if (!_speechReady) {
      _speechReady = await SpeechService.initialize();
      if (!_speechReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('麦克风不可用，请在系统设置中授权后重试'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }
    setState(() => _isRecording = true);
    _pulseCtrl.repeat(reverse: true);
    await SpeechService.startListening(
      onResult: (_, __) {},
    );
  }

  Future<void> _stopRecording() async {
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    setState(() => _isRecording = false);

    final text = await SpeechService.stopListening();
    if (!mounted || text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未识别到语音内容，请重试'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final parsed = TodoParserService.parse(text);
    if (parsed.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未解析出有效任务，请重试'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    TodoVoiceAddPage.showPreview(context, text, parsed);
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
                    onSelected: (_) => ref.read(todoProvider.notifier).setFilter(filter),
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
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
              if (todoState.filter == TodoFilter.all) ...[
                const SizedBox(width: 12),
                if (todoState.overdueCount > 0)
                  Text('${todoState.overdueCount} 项逾期',
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.red)),
              ],
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
                      subtitle: '点击下方按钮添加新任务',
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
                          onTap: () => AppRouter.goTodoDetail(context, todo.id!),
                          onToggle: () => ref.read(todoProvider.notifier).toggleComplete(todo.id!),
                          onDelete: () => _deleteTodo(context, ref, todo),
                        );
                      },
                    ),
        ),

        // 底部添加入口
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
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.edit_note, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text('手动添加', style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      )),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  onLongPressCancel: () => _stopRecording(),
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) => Transform.scale(
                      scale: _isRecording ? _pulseAnim.value : 1.0,
                      child: child,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(
                          _isRecording ? Icons.mic : Icons.mic_none,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isRecording ? '松开停止' : '语音添加',
                          style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ]),
                    ),
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
      case TodoFilter.all: return '全部';
      case TodoFilter.incomplete: return '未完成';
      case TodoFilter.completed: return '已完成';
      case TodoFilter.highPriority: return '高优先级';
      case TodoFilter.overdue: return '已逾期';
    }
  }

  String _emptyTitle(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all: return '还没有待办任务';
      case TodoFilter.incomplete: return '没有未完成任务';
      case TodoFilter.completed: return '没有已完成任务';
      case TodoFilter.highPriority: return '没有高优先级任务';
      case TodoFilter.overdue: return '没有逾期任务';
    }
  }

  Future<void> _deleteTodo(BuildContext context, WidgetRef ref, TodoItem todo) async {
    final ok = await ConfirmDialog.show(context,
      title: '删除待办', content: '确定删除「${todo.title}」？',
      confirmLabel: '删除', confirmColor: Colors.red,
    );
    if (ok == true) {
      await ref.read(todoProvider.notifier).deleteTodo(todo.id!);
    }
  }
}
