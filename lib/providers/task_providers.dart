import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_service.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import '../models/task_filter.dart';
import 'filter_providers.dart';
import 'repository_providers.dart';

class TaskListNotifier extends Notifier<List<Task>> {
  @override
  List<Task> build() {
    final repo = ref.watch(taskRepositoryProvider);
    final subscription = repo.watch().listen((_) => state = repo.getAll());
    ref.onDispose(subscription.cancel);
    return repo.getAll();
  }

  TaskRepository get _tasks => ref.read(taskRepositoryProvider);
  NotificationService get _notifications =>
      ref.read(notificationServiceProvider);

  Future<Task> add({
    required String title,
    String? notes,
    DateTime? dueDate,
    String? categoryId,
    int? reminderMinutesBefore,
  }) async {
    final task = await _tasks.create(
      title: title,
      notes: notes,
      dueDate: dueDate,
      categoryId: categoryId,
      reminderMinutesBefore: reminderMinutesBefore,
    );
    await _notifications.syncReminder(task);
    return task;
  }

  Future<void> update(Task task) async {
    await _tasks.update(task);
    await _notifications.syncReminder(task);
  }

  Future<void> delete(Task task) async {
    await _tasks.delete(task.id);
    await _notifications.cancel(task.notificationId);
  }

  Future<Task> toggleComplete(Task task) async {
    final updated = await _tasks.toggleComplete(task);
    await _notifications.syncReminder(updated);
    return updated;
  }

  Future<void> clearCompleted() async {
    final removed = await _tasks.clearCompleted();
    for (final id in removed) {
      await _notifications.cancel(id.hashCode & 0x7FFFFFFF);
    }
  }

  Future<void> resyncAllReminders() => _notifications.rescheduleAll(state);
}

final taskListProvider = NotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);

class CategoryListNotifier extends Notifier<List<TaskCategory>> {
  @override
  List<TaskCategory> build() {
    final repo = ref.watch(categoryRepositoryProvider);
    final subscription = repo.watch().listen((_) => state = repo.getAll());
    ref.onDispose(subscription.cancel);
    return repo.getAll();
  }

  Future<void> add({
    required String name,
    required int colorValue,
    required int iconIndex,
  }) async {
    await ref
        .read(categoryRepositoryProvider)
        .create(name: name, colorValue: colorValue, iconIndex: iconIndex);
  }

  Future<void> update(TaskCategory category) =>
      ref.read(categoryRepositoryProvider).update(category);

  Future<void> delete(TaskCategory category) async {
    await ref.read(taskRepositoryProvider).detachCategory(category.id);
    await ref.read(categoryRepositoryProvider).delete(category.id);

    final filter = ref.read(taskFilterProvider);
    if (filter.categoryId == category.id) {
      ref.read(taskFilterProvider.notifier).clearCategory();
    }
  }
}

final categoryListProvider =
    NotifierProvider<CategoryListNotifier, List<TaskCategory>>(
      CategoryListNotifier.new,
    );

final categoryMapProvider = Provider<Map<String, TaskCategory>>((ref) {
  final categories = ref.watch(categoryListProvider);
  return {for (final c in categories) c.id: c};
});

final visibleTasksProvider = Provider<List<Task>>((ref) {
  return queryTasks(
    tasks: ref.watch(taskListProvider),
    filter: ref.watch(taskFilterProvider),
    sort: ref.watch(sortOptionProvider),
    categories: ref.watch(categoryMapProvider),
  );
});

final statusCountsProvider = Provider<Map<TaskStatusFilter, int>>((ref) {
  final tasks = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);
  return {
    for (final status in TaskStatusFilter.values)
      status: tasks.where(filter.copyWith(status: status).matches).length,
  };
});

final hasCompletedTasksProvider = Provider<bool>(
  (ref) => ref.watch(taskListProvider).any((t) => t.isCompleted),
);
