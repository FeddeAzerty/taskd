import 'package:flutter/foundation.dart';

import 'task.dart';
import 'task_category.dart';

enum TaskStatusFilter {
  all('All'),
  active('Active'),
  completed('Done');

  const TaskStatusFilter(this.label);
  final String label;
}

enum DueDateFilter {
  any('Any date'),
  overdue('Overdue'),
  today('Today'),
  thisWeek('Next 7 days'),
  noDueDate('No due date');

  const DueDateFilter(this.label);
  final String label;
}

enum SortOption {
  dueDateAsc('Due date (soonest)'),
  dueDateDesc('Due date (latest)'),
  createdDesc('Recently added'),
  createdAsc('Oldest first'),
  alphabetical('Title (A–Z)'),
  category('Category');

  const SortOption(this.label);
  final String label;
}

@immutable
class TaskFilter {
  const TaskFilter({
    this.status = TaskStatusFilter.active,
    this.categoryId,
    this.dueDate = DueDateFilter.any,
    this.query = '',
  });

  final TaskStatusFilter status;

  final String? categoryId;

  final DueDateFilter dueDate;
  final String query;

  bool get hasRefinements =>
      categoryId != null || dueDate != DueDateFilter.any || query.isNotEmpty;

  TaskFilter copyWith({
    TaskStatusFilter? status,
    String? categoryId,
    DueDateFilter? dueDate,
    String? query,
    bool clearCategory = false,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      dueDate: dueDate ?? this.dueDate,
      query: query ?? this.query,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TaskFilter &&
      other.status == status &&
      other.categoryId == categoryId &&
      other.dueDate == dueDate &&
      other.query == query;

  @override
  int get hashCode => Object.hash(status, categoryId, dueDate, query);

  bool matches(Task task) {
    switch (status) {
      case TaskStatusFilter.active:
        if (task.isCompleted) return false;
      case TaskStatusFilter.completed:
        if (!task.isCompleted) return false;
      case TaskStatusFilter.all:
        break;
    }

    if (categoryId != null && task.categoryId != categoryId) return false;

    if (!_matchesDueDate(task)) return false;

    if (query.isNotEmpty) {
      final needle = query.toLowerCase();
      final inTitle = task.title.toLowerCase().contains(needle);
      final inNotes = task.notes?.toLowerCase().contains(needle) ?? false;
      if (!inTitle && !inNotes) return false;
    }

    return true;
  }

  bool _matchesDueDate(Task task) {
    final due = task.dueDate;
    switch (dueDate) {
      case DueDateFilter.any:
        return true;
      case DueDateFilter.noDueDate:
        return due == null;
      case DueDateFilter.overdue:
        return due != null && !task.isCompleted && due.isBefore(DateTime.now());
      case DueDateFilter.today:
        if (due == null) return false;
        final now = DateTime.now();
        return due.year == now.year &&
            due.month == now.month &&
            due.day == now.day;
      case DueDateFilter.thisWeek:
        if (due == null) return false;
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final end = startOfToday.add(const Duration(days: 7));
        return !due.isBefore(startOfToday) && due.isBefore(end);
    }
  }
}

List<Task> queryTasks({
  required List<Task> tasks,
  required TaskFilter filter,
  required SortOption sort,
  required Map<String, TaskCategory> categories,
}) {
  final result = tasks.where(filter.matches).toList();
  result.sort(_comparatorFor(sort, categories));
  return List.unmodifiable(result);
}

Comparator<Task> _comparatorFor(
  SortOption sort,
  Map<String, TaskCategory> categories,
) {
  switch (sort) {
    case SortOption.dueDateAsc:
      return (a, b) => _byDueDate(a, b, ascending: true);
    case SortOption.dueDateDesc:
      return (a, b) => _byDueDate(a, b, ascending: false);
    case SortOption.createdDesc:
      return (a, b) => b.createdAt.compareTo(a.createdAt);
    case SortOption.createdAsc:
      return (a, b) => a.createdAt.compareTo(b.createdAt);
    case SortOption.alphabetical:
      return (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase());
    case SortOption.category:
      return (a, b) {
        final an = categories[a.categoryId]?.name;
        final bn = categories[b.categoryId]?.name;

        if (an == null && bn == null) return _byDueDate(a, b, ascending: true);
        if (an == null) return 1;
        if (bn == null) return -1;
        final byName = an.toLowerCase().compareTo(bn.toLowerCase());
        return byName != 0 ? byName : _byDueDate(a, b, ascending: true);
      };
  }
}

int _byDueDate(Task a, Task b, {required bool ascending}) {
  final ad = a.dueDate;
  final bd = b.dueDate;
  if (ad == null && bd == null) return b.createdAt.compareTo(a.createdAt);
  if (ad == null) return 1;
  if (bd == null) return -1;
  return ascending ? ad.compareTo(bd) : bd.compareTo(ad);
}
