import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/task_filter.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.filter,
    required this.hasAnyTasks,
    required this.onClearFilters,
    super.key,
  });

  final TaskFilter filter;
  final bool hasAnyTasks;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, title, subtitle) = _content();

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.enter,
        curve: AppMotion.entering,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 38, color: scheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (filter.hasRefinements) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear filters'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (IconData, String, String) _content() {
    if (!hasAnyTasks) {
      return (
        Icons.checklist_rounded,
        'Nothing to do yet',
        'Tap the + button to add your first task.',
      );
    }
    if (filter.hasRefinements) {
      return (
        Icons.search_off_rounded,
        'No matching tasks',
        'Nothing fits the filters you have set.',
      );
    }
    return switch (filter.status) {
      TaskStatusFilter.active => (
        Icons.celebration_outlined,
        'All caught up',
        'Every task is done. Enjoy the quiet.',
      ),
      TaskStatusFilter.completed => (
        Icons.inbox_outlined,
        'Nothing completed yet',
        'Finished tasks will collect here.',
      ),
      TaskStatusFilter.all => (
        Icons.checklist_rounded,
        'Nothing to do yet',
        'Tap the + button to add your first task.',
      ),
    };
  }
}
