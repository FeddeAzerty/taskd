import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/task_filter.dart';
import '../providers/filter_providers.dart';
import '../providers/task_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/task_tile.dart';
import 'category_manager_sheet.dart';
import 'task_editor_sheet.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        ref.read(taskFilterProvider.notifier).setQuery('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(visibleTasksProvider);
    final categories = ref.watch(categoryMapProvider);
    final filter = ref.watch(taskFilterProvider);
    final hasAnyTasks = ref.watch(taskListProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tasks…',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 18),
                onChanged: (value) =>
                    ref.read(taskFilterProvider.notifier).setQuery(value),
              )
            : const Text('Taskd'),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: _searching ? 'Close search' : 'Search',
          ),
          const _SortButton(),
          const _OverflowMenu(),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          const FilterBar(),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? EmptyState(
                    filter: filter,
                    hasAnyTasks: hasAnyTasks,
                    onClearFilters: () {
                      _searchController.clear();
                      if (_searching) setState(() => _searching = false);
                      ref.read(taskFilterProvider.notifier).clearRefinements();
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        category: categories[task.categoryId],
                        onEdit: () => TaskEditorSheet.show(context, task: task),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TaskEditorSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}

class _SortButton extends ConsumerWidget {
  const _SortButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sortOptionProvider);

    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.swap_vert_rounded),
      tooltip: 'Sort',
      initialValue: current,
      onSelected: (option) => ref.read(sortOptionProvider.notifier).set(option),
      itemBuilder: (context) => [
        for (final option in SortOption.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Icon(
                  option == current
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 17,
                  color: option == current
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Text(option.label, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
      ],
    );
  }
}

class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final filter = ref.watch(taskFilterProvider);
    final hasCompleted = ref.watch(hasCompletedTasksProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'More',
      onSelected: (value) async {
        switch (value) {
          case 'theme':
            await ref.read(themeModeProvider.notifier).cycle();
          case 'categories':
            if (context.mounted) await CategoryManagerSheet.show(context);
          case 'clear':
            await _confirmClearCompleted(context, ref);
          default:
            final due = DueDateFilter.values.firstWhere((d) => d.name == value);
            ref.read(taskFilterProvider.notifier).setDueDate(due);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(_themeIcon(themeMode), size: 18),
              const SizedBox(width: 12),
              Text('Theme: ${_themeLabel(themeMode)}'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'categories',
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 18),
              SizedBox(width: 12),
              Text('Manage categories'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        for (final due in DueDateFilter.values)
          CheckedPopupMenuItem(
            value: due.name,
            checked: filter.dueDate == due,
            child: Text(due.label, style: const TextStyle(fontSize: 13.5)),
          ),
        if (hasCompleted) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'clear',
            child: Row(
              children: [
                Icon(Icons.delete_sweep_outlined, size: 18),
                SizedBox(width: 12),
                Text('Clear completed'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static IconData _themeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };

  static String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  Future<void> _confirmClearCompleted(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final count = ref.read(taskListProvider).where((t) => t.isCompleted).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear completed?'),
        content: Text(
          '$count completed ${count == 1 ? 'task' : 'tasks'} will be deleted '
          'permanently.',
        ),
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(taskListProvider.notifier).clearCompleted();
  }
}

const Duration kFilterSettle = AppMotion.quick;
