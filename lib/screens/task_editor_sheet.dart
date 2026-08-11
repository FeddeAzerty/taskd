import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_format.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';
import 'category_manager_sheet.dart';

class TaskEditorSheet extends ConsumerStatefulWidget {
  const TaskEditorSheet({this.task, super.key});

  final Task? task;

  static Future<void> show(BuildContext context, {Task? task}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TaskEditorSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.task?.title ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.task?.notes ?? '',
  );
  final _formKey = GlobalKey<FormState>();

  late DateTime? _dueDate = widget.task?.dueDate;
  late String? _categoryId = widget.task?.categoryId;
  late int? _reminderMinutes = widget.task?.reminderMinutesBefore;

  bool get _isEditing => widget.task != null;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
    );
    if (!mounted) return;

    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );

      _reminderMinutes ??= 0;
    });
  }

  void _clearDueDate() => setState(() {
    _dueDate = null;
    _reminderMinutes = null;
  });

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(taskListProvider.notifier);
    final title = _title.text.trim();
    final notes = _notes.text.trim();
    final existing = widget.task;

    if (existing == null) {
      await notifier.add(
        title: title,
        notes: notes,
        dueDate: _dueDate,
        categoryId: _categoryId,
        reminderMinutesBefore: _reminderMinutes,
      );
    } else {
      await notifier.update(
        existing.copyWith(
          title: title,
          notes: notes,
          clearNotes: notes.isEmpty,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          categoryId: _categoryId,
          clearCategory: _categoryId == null,
          reminderMinutesBefore: _reminderMinutes,
          clearReminder: _reminderMinutes == null,
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final categories = ref.watch(categoryListProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isEditing ? 'Edit task' : 'New task',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _title,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'What needs doing?',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Give the task a title'
                      : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Notes (optional)',
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel('Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChoicePill(
                      label: 'None',
                      selected: _categoryId == null,
                      color: scheme.outline,
                      onTap: () => setState(() => _categoryId = null),
                    ),
                    for (final category in categories)
                      _ChoicePill(
                        label: category.name,
                        icon: category.icon,
                        color: category.color,
                        selected: _categoryId == category.id,
                        onTap: () => setState(() => _categoryId = category.id),
                      ),
                    _ChoicePill(
                      label: 'Manage',
                      icon: Icons.tune_rounded,
                      color: scheme.outline,
                      selected: false,
                      onTap: () => CategoryManagerSheet.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionLabel('Due date'),
                const SizedBox(height: 8),
                _DueDateRow(
                  dueDate: _dueDate,
                  onPick: _pickDueDate,
                  onClear: _clearDueDate,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _dueDate == null
                      ? const SizedBox(width: double.infinity)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 22),
                            _SectionLabel('Remind me'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _ChoicePill(
                                  label: 'Off',
                                  selected: _reminderMinutes == null,
                                  color: scheme.outline,
                                  onTap: () =>
                                      setState(() => _reminderMinutes = null),
                                ),
                                for (final minutes in ReminderLabels.offsets)
                                  _ChoicePill(
                                    label: ReminderLabels.label(minutes),
                                    selected: _reminderMinutes == minutes,
                                    color: scheme.primary,
                                    onTap: () => setState(
                                      () => _reminderMinutes = minutes,
                                    ),
                                  ),
                              ],
                            ),
                            if (_reminderWarning case final warning?) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 15,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      warning,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    if (_isEditing)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _confirmDelete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                    if (_isEditing) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _save,
                        child: Text(_isEditing ? 'Save changes' : 'Add task'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? get _reminderWarning {
    final due = _dueDate;
    final offset = _reminderMinutes;
    if (due == null || offset == null) return null;
    final fireAt = due.subtract(Duration(minutes: offset));
    if (fireAt.isAfter(DateTime.now())) return null;
    return 'That reminder time has already passed, so no notification will be '
        'scheduled.';
  }

  Future<void> _confirmDelete() async {
    final task = widget.task;
    if (task == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(taskListProvider.notifier).delete(task);
    if (mounted) Navigator.of(context).pop();
  }
}

class _DueDateRow extends StatelessWidget {
  const _DueDateRow({
    required this.dueDate,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = dueDate;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                due == null ? 'Set a due date' : DateLabels.fullLabel(due),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              foregroundColor: due == null ? scheme.onSurfaceVariant : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (due != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Clear due date',
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: selected ? scheme.onPrimary : color,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? scheme.onPrimary : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
