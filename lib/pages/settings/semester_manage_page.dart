import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/semester.dart';
import '../../providers/semester_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/todo_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../utils/app_strings.dart';
import '../../widgets/common/confirm_dialog.dart';

/// 学期管理页面
class SemesterManagePage extends ConsumerStatefulWidget {
  const SemesterManagePage({super.key});

  @override
  ConsumerState<SemesterManagePage> createState() => _SemesterManagePageState();
}

class _SemesterManagePageState extends ConsumerState<SemesterManagePage> {
  Future<void> _editSemester(Semester? semester) async {
    final result = await _showSemesterDialog(semester);
    if (result == null) return;

    if (semester == null) {
      await ref.read(semesterProvider.notifier).addSemester(result);
    } else {
      await ref.read(semesterProvider.notifier).updateSemester(result.copyWith(id: semester.id));
    }
  }

  Future<Semester?> _showSemesterDialog(Semester? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final startCtrl = TextEditingController(
      text: existing?.startDate.toIso8601String().split('T').first ?? '',
    );
    final endCtrl = TextEditingController(
      text: existing?.endDate.toIso8601String().split('T').first ?? '',
    );
    final weeksCtrl = TextEditingController(
      text: '${existing?.totalWeeks ?? 18}',
    );

    return showDialog<Semester>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '新建学期' : '编辑学期'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '学期名称', hintText: '2025-2026学年第一学期'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startCtrl,
                decoration: const InputDecoration(labelText: '开学日期', hintText: '2025-09-01'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endCtrl,
                decoration: const InputDecoration(labelText: '结束日期', hintText: '2026-01-15'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weeksCtrl,
                decoration: const InputDecoration(labelText: '总周数', hintText: '18'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final startStr = startCtrl.text.trim();
              final endStr = endCtrl.text.trim();
              final weeks = int.tryParse(weeksCtrl.text.trim());

              if (name.isEmpty || startStr.isEmpty || endStr.isEmpty || weeks == null) {
                return;
              }

              final startDate = DateTime.tryParse(startStr);
              final endDate = DateTime.tryParse(endStr);
              if (startDate == null || endDate == null) return;

              Navigator.pop(
                ctx,
                Semester(
                  name: name,
                  startDate: startDate,
                  endDate: endDate,
                  totalWeeks: weeks,
                ),
              );
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(semesterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.semesterManagement)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.semesters.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.school_outlined,
                  title: AppStrings.semesterNone,
                  subtitle: AppStrings.semesterNoneHint,
                  actionLabel: '新建学期',
                  onAction: () => _editSemester(null),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.semesters.length,
                  itemBuilder: (context, index) {
                    final s = state.semesters[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          s.isCurrent ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: s.isCurrent ? theme.colorScheme.primary : null,
                        ),
                        title: Text(s.name, style: theme.textTheme.bodyLarge),
                        subtitle: Text(
                          '${s.startDate.toIso8601String().split('T').first} ~ ${s.endDate.toIso8601String().split('T').first} · ${s.totalWeeks}周',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'current') {
                              await ref.read(semesterProvider.notifier).setCurrentSemester(s.id!);
                            } else if (action == 'edit') {
                              _editSemester(s);
                            } else if (action == 'delete') {
                              final ok = await ConfirmDialog.show(
                                context,
                                title: AppStrings.semesterDeleteTitle,
                                content: '删除「${s.name}」及其所有课程和待办？此操作不可撤销。',
                                confirmLabel: AppStrings.semesterDeleteConfirm,
                                confirmColor: Colors.red,
                              );
                              if (ok == true) {
                                await ref.read(semesterProvider.notifier).deleteSemester(s.id!);
                                // 学期删除会级联删除课程，刷新课程和待办
                                await ref.read(courseProvider.notifier).loadCourses();
                                await ref.read(todoProvider.notifier).loadTodos();
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            if (!s.isCurrent)
                              const PopupMenuItem(value: 'current', child: Text(AppStrings.semesterSetCurrent)),
                            const PopupMenuItem(value: 'edit', child: Text(AppStrings.edit)),
                            const PopupMenuItem(value: 'delete', child: Text(AppStrings.semesterDeleteConfirm, style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editSemester(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
