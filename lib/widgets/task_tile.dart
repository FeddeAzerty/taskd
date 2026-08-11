import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/date_format.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import '../providers/filter_providers.dart';
import '../providers/task_providers.dart';
import 'completion_checkbox.dart';
import 'strikethrough_text.dart';

class TaskTile extends ConsumerStatefulWidget {
  const TaskTile({
    required this.task,
    required this.category,
    required this.onEdit,
    super.key,
  });

  final Task task;
  final TaskCategory? category;
  final VoidCallback onEdit;

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile>
    with TickerProviderStateMixin {
  late final AnimationController _strike = AnimationController(
    vsync: this,
    duration: AppMotion.strike,
    value: widget.task.isCompleted ? 1 : 0,
  );

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: AppMotion.collapse,
  );

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.enter,
  )..forward();

  bool _busy = false;

  @override
  void didUpdateWidget(TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_busy && widget.task.isCompleted != oldWidget.task.isCompleted) {
      widget.task.isCompleted ? _strike.forward() : _strike.reverse();
    }
  }

  @override
  void dispose() {
    _strike.dispose();
    _exit.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _toggleCompletion() async {
    if (_busy) return;
    _busy = true;

    final task = widget.task;
    final becomingComplete = !task.isCompleted;

    final afterToggle = task.copyWith(
      isCompleted: becomingComplete,
      completedAt: becomingComplete ? DateTime.now() : null,
      clearCompletedAt: !becomingComplete,
    );
    final willLeaveView = !ref.read(taskFilterProvider).matches(afterToggle);

    unawaited(HapticFeedback.selectionClick());

    await (becomingComplete ? _strike.forward() : _strike.reverse());
    if (!mounted) return;

    if (willLeaveView) {
      await _exit.forward();
      if (!mounted) return;
    }

    await ref.read(taskListProvider.notifier).toggleComplete(task);

    if (mounted) _busy = false;
  }

  Future<void> _delete() async {
    final task = widget.task;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(taskListProvider.notifier);

    await notifier.delete(task);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => notifier.update(task),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final task = widget.task;
    final accent = widget.category?.color ?? scheme.primary;

    final titleStyle = theme.textTheme.bodyLarge!.copyWith(
      fontSize: 15.5,
      fontWeight: FontWeight.w500,
      height: 1.3,
    );

    return SizeTransition(
      sizeFactor: Tween<double>(
        begin: 1,
        end: 0,
      ).animate(CurvedAnimation(parent: _exit, curve: AppMotion.leaving)),
      axisAlignment: 0,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(
          CurvedAnimation(
            parent: _exit,
            curve: const Interval(0, 0.65, curve: Curves.easeOut),
          ),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0.08, 0),
          ).animate(CurvedAnimation(parent: _exit, curve: AppMotion.leaving)),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _entrance,
              curve: AppMotion.entering,
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _entrance,
                      curve: AppMotion.entering,
                    ),
                  ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCard(theme, scheme, task, accent, titleStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    ThemeData theme,
    ColorScheme scheme,
    Task task,
    Color accent,
    TextStyle titleStyle,
  ) {
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(scheme),
      onDismissed: (_) => _delete(),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AnimatedBuilder(
                    animation: _strike,
                    builder: (context, _) => CompletionCheckbox(
                      checked: _strike.value > 0.5,
                      color: accent,
                      onTap: _toggleCompletion,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _strike,
                        builder: (context, _) {
                          final faded = Color.lerp(
                            titleStyle.color ?? scheme.onSurface,
                            scheme.onSurfaceVariant.withValues(alpha: 0.55),
                            Curves.easeOut.transform(_strike.value),
                          );
                          return StrikethroughText(
                            text: task.title,
                            progress: AppMotion.strikeCurve.transform(
                              _strike.value,
                            ),
                            style: titleStyle.copyWith(color: faded),
                          );
                        },
                      ),
                      if (task.notes case final notes?
                          when notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                      _buildMetaRow(theme, scheme, task, accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    ThemeData theme,
    ColorScheme scheme,
    Task task,
    Color accent,
  ) {
    final category = widget.category;
    final due = task.dueDate;
    final reminder = task.reminderMinutesBefore;

    if (category == null && due == null) return const SizedBox.shrink();

    final overdue = task.isOverdue;
    final dueColor = overdue ? scheme.error : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (category != null)
            _MetaChip(
              icon: category.icon,
              label: category.name,
              color: accent,
              tinted: true,
            ),
          if (due != null)
            _MetaChip(
              icon: overdue
                  ? Icons.error_outline_rounded
                  : Icons.event_outlined,
              label: DateLabels.dueLabel(due),
              color: dueColor,
              bold: overdue,
            ),
          if (due != null && reminder != null)
            _MetaChip(
              icon: Icons.notifications_none_rounded,
              label: ReminderLabels.shortLabel(reminder),
              color: scheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }

  Widget _deleteBackground(ColorScheme scheme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    this.tinted = false,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final Color color;

  final bool tinted;

  final bool bold;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: color,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );

    if (!tinted) return content;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: content,
    );
  }
}
