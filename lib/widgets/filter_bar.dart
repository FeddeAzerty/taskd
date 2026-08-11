import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/task_filter.dart';
import '../providers/filter_providers.dart';
import '../providers/task_providers.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final counts = ref.watch(statusCountsProvider);
    final categories = ref.watch(categoryListProvider);
    final notifier = ref.read(taskFilterProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<TaskStatusFilter>(
            segments: [
              for (final status in TaskStatusFilter.values)
                ButtonSegment(
                  value: status,
                  label: Text('${status.label} (${counts[status] ?? 0})'),
                ),
            ],
            selected: {filter.status},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                notifier.setStatus(selection.first),
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              children: [
                _CategoryChip(
                  label: 'All',
                  color: scheme.primary,
                  selected: filter.categoryId == null,
                  onTap: notifier.clearCategory,
                ),
                for (final category in categories)
                  _CategoryChip(
                    label: category.name,
                    icon: category.icon,
                    color: category.color,
                    selected: filter.categoryId == category.id,
                    onTap: () => notifier.toggleCategory(category.id),
                  ),
              ],
            ),
          ),
        if (filter.dueDate != DueDateFilter.any)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.event_outlined, size: 15),
                  label: Text(filter.dueDate.label),
                  onDeleted: () => notifier.setDueDate(DueDateFilter.any),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  backgroundColor: scheme.secondaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        curve: AppMotion.entering,
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      ),
    );
  }
}
