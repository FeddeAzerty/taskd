import 'package:flutter_test/flutter_test.dart';
import 'package:taskd/models/task.dart';
import 'package:taskd/models/task_category.dart';
import 'package:taskd/models/task_filter.dart';

void main() {
  final now = DateTime(2026, 8, 11, 12);

  Task task({
    required String id,
    String title = 'Task',
    bool done = false,
    DateTime? due,
    String? categoryId,
    DateTime? created,
    String? notes,
  }) {
    return Task(
      id: id,
      title: title,
      createdAt: created ?? now,
      isCompleted: done,
      dueDate: due,
      categoryId: categoryId,
      notes: notes,
    );
  }

  const noCategories = <String, TaskCategory>{};

  group('status filter', () {
    final tasks = [
      task(id: 'a', title: 'Active one'),
      task(id: 'b', title: 'Done one', done: true),
    ];

    test('active hides completed tasks', () {
      final result = queryTasks(
        tasks: tasks,
        filter: const TaskFilter(status: TaskStatusFilter.active),
        sort: SortOption.createdDesc,
        categories: noCategories,
      );
      expect(result.map((t) => t.id), ['a']);
    });

    test('completed shows only completed tasks', () {
      final result = queryTasks(
        tasks: tasks,
        filter: const TaskFilter(status: TaskStatusFilter.completed),
        sort: SortOption.createdDesc,
        categories: noCategories,
      );
      expect(result.map((t) => t.id), ['b']);
    });

    test('all shows everything', () {
      final result = queryTasks(
        tasks: tasks,
        filter: const TaskFilter(status: TaskStatusFilter.all),
        sort: SortOption.createdDesc,
        categories: noCategories,
      );
      expect(result.length, 2);
    });
  });

  group('sorting by due date', () {
    test('undated tasks sink to the bottom in both directions', () {
      final tasks = [
        task(id: 'none'),
        task(id: 'late', due: now.add(const Duration(days: 5))),
        task(id: 'soon', due: now.add(const Duration(days: 1))),
      ];

      final ascending = queryTasks(
        tasks: tasks,
        filter: const TaskFilter(status: TaskStatusFilter.all),
        sort: SortOption.dueDateAsc,
        categories: noCategories,
      );
      expect(ascending.map((t) => t.id), ['soon', 'late', 'none']);

      final descending = queryTasks(
        tasks: tasks,
        filter: const TaskFilter(status: TaskStatusFilter.all),
        sort: SortOption.dueDateDesc,
        categories: noCategories,
      );

      expect(descending.map((t) => t.id), ['late', 'soon', 'none']);
    });
  });

  group('sorting by category', () {
    test('groups by name and puts uncategorised last', () {
      final categories = {
        'w': TaskCategory(
          id: 'w',
          name: 'Work',
          colorValue: 0xFF000000,
          iconIndex: 0,
          createdAt: now,
        ),
        'e': TaskCategory(
          id: 'e',
          name: 'Errands',
          colorValue: 0xFF000000,
          iconIndex: 0,
          createdAt: now,
        ),
      };

      final result = queryTasks(
        tasks: [
          task(id: 'none'),
          task(id: 'work', categoryId: 'w'),
          task(id: 'errand', categoryId: 'e'),
        ],
        filter: const TaskFilter(status: TaskStatusFilter.all),
        sort: SortOption.category,
        categories: categories,
      );

      expect(result.map((t) => t.id), ['errand', 'work', 'none']);
    });
  });

  group('search', () {
    test('matches title and notes, case insensitively', () {
      final tasks = [
        task(id: 'a', title: 'Buy MILK'),
        task(id: 'b', title: 'Call bank', notes: 'ask about the milk float'),
        task(id: 'c', title: 'Water plants'),
      ];

      final result = queryTasks(
        tasks: tasks,
        filter: const TaskFilter(status: TaskStatusFilter.all, query: 'milk'),
        sort: SortOption.createdDesc,
        categories: noCategories,
      );

      expect(result.map((t) => t.id).toSet(), {'a', 'b'});
    });
  });

  group('due date buckets', () {
    test('overdue excludes completed tasks', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final tasks = [
        task(id: 'open', due: past),
        task(id: 'closed', due: past, done: true),
      ];

      final result = queryTasks(
        tasks: tasks,
        filter: const TaskFilter(
          status: TaskStatusFilter.all,
          dueDate: DueDateFilter.overdue,
        ),
        sort: SortOption.createdDesc,
        categories: noCategories,
      );

      expect(result.map((t) => t.id), ['open']);
    });

    test('noDueDate selects exactly the undated tasks', () {
      final result = queryTasks(
        tasks: [
          task(id: 'undated'),
          task(id: 'dated', due: now),
        ],
        filter: const TaskFilter(
          status: TaskStatusFilter.all,
          dueDate: DueDateFilter.noDueDate,
        ),
        sort: SortOption.createdDesc,
        categories: noCategories,
      );
      expect(result.map((t) => t.id), ['undated']);
    });
  });

  group('Task reminder logic', () {
    test('reminderTime subtracts the lead time from the due date', () {
      final due = DateTime.now().add(const Duration(days: 1));
      final t = Task(
        id: 'x',
        title: 'x',
        createdAt: now,
        dueDate: due,
        reminderMinutesBefore: 60,
      );
      expect(t.reminderTime, due.subtract(const Duration(minutes: 60)));
      expect(t.hasSchedulableReminder, isTrue);
    });

    test('a reminder in the past is not schedulable', () {
      final t = Task(
        id: 'x',
        title: 'x',
        createdAt: now,
        dueDate: DateTime.now().subtract(const Duration(hours: 2)),
        reminderMinutesBefore: 0,
      );
      expect(t.hasSchedulableReminder, isFalse);
    });

    test('a completed task never holds a schedulable reminder', () {
      final t = Task(
        id: 'x',
        title: 'x',
        createdAt: now,
        isCompleted: true,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        reminderMinutesBefore: 0,
      );
      expect(t.hasSchedulableReminder, isFalse);
    });

    test('clearing the due date also clears the reminder', () {
      final t = Task(
        id: 'x',
        title: 'x',
        createdAt: now,
        dueDate: DateTime.now(),
        reminderMinutesBefore: 30,
      ).copyWith(clearDueDate: true);

      expect(t.dueDate, isNull);
      expect(t.reminderMinutesBefore, isNull);
      expect(t.reminderTime, isNull);
    });

    test('notificationId is stable and non-negative', () {
      final t = task(id: 'stable-id');
      expect(t.notificationId, task(id: 'stable-id').notificationId);
      expect(t.notificationId, greaterThanOrEqualTo(0));
    });
  });
}
