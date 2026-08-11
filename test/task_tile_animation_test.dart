import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskd/models/task.dart';
import 'package:taskd/models/task_filter.dart';
import 'package:taskd/providers/filter_providers.dart';
import 'package:taskd/providers/task_providers.dart';
import 'package:taskd/widgets/strikethrough_text.dart';
import 'package:taskd/widgets/task_tile.dart';

class _RecordingNotifier extends TaskListNotifier {
  _RecordingNotifier(this._seed);

  final List<Task> _seed;

  bool committed = false;

  @override
  List<Task> build() => _seed;

  @override
  Future<Task> toggleComplete(Task task) async {
    committed = true;
    return task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: task.isCompleted ? null : DateTime.now(),
      clearCompletedAt: task.isCompleted,
    );
  }
}

void main() {
  Task makeTask({bool completed = false}) => Task(
    id: 't1',
    title: 'Buy groceries',
    createdAt: DateTime(2026, 8, 11),
    isCompleted: completed,
    completedAt: completed ? DateTime(2026, 8, 11) : null,
  );

  Future<_RecordingNotifier> pumpTile(
    WidgetTester tester,
    Task task, {
    TaskFilter filter = const TaskFilter(),
  }) async {
    final notifier = _RecordingNotifier([task]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskListProvider.overrideWith(() => notifier),
          taskFilterProvider.overrideWith(() => _FixedFilter(filter)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TaskTile(
              key: ValueKey(task.id),
              task: task,
              category: null,
              onEdit: () {},
            ),
          ),
        ),
      ),
    );
    return notifier;
  }

  double strikeProgress(WidgetTester tester) =>
      tester.widget<StrikethroughText>(find.byType(StrikethroughText)).progress;

  Finder checkbox() => find.byType(InkResponse);

  testWidgets('draws the line across the title before committing', (
    tester,
  ) async {
    final notifier = await pumpTile(tester, makeTask());
    expect(strikeProgress(tester), 0, reason: 'starts unstruck');

    await tester.tap(checkbox());
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 170));
    final midway = strikeProgress(tester);
    expect(midway, greaterThan(0));
    expect(midway, lessThan(1));
    expect(
      notifier.committed,
      isFalse,
      reason: 'must not commit while the line is still being drawn',
    );

    await tester.pump(const Duration(milliseconds: 220));
    expect(strikeProgress(tester), 1);
    expect(
      notifier.committed,
      isFalse,
      reason: 'must not commit while the row is still collapsing',
    );

    await tester.pumpAndSettle();
    expect(
      notifier.committed,
      isTrue,
      reason: 'commits once the animation has finished',
    );
  });

  testWidgets('a task loaded already complete renders struck immediately', (
    tester,
  ) async {
    await pumpTile(tester, makeTask(completed: true));

    expect(strikeProgress(tester), 1);
  });

  testWidgets('un-completing retracts the line', (tester) async {
    final notifier = await pumpTile(
      tester,
      makeTask(completed: true),
      filter: const TaskFilter(status: TaskStatusFilter.completed),
    );
    expect(strikeProgress(tester), 1);

    await tester.tap(checkbox());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 170));
    expect(strikeProgress(tester), lessThan(1), reason: 'line is retracting');

    await tester.pumpAndSettle();
    expect(notifier.committed, isTrue);
  });

  testWidgets(
    'under the All filter the row keeps its line instead of leaving',
    (tester) async {
      final notifier = await pumpTile(
        tester,
        makeTask(),
        filter: const TaskFilter(status: TaskStatusFilter.all),
      );

      await tester.tap(checkbox());
      await tester.pumpAndSettle();

      expect(notifier.committed, isTrue);
      expect(strikeProgress(tester), 1);

      expect(find.byType(StrikethroughText), findsOneWidget);
      expect(tester.getSize(find.byType(TaskTile)).height, greaterThan(0));
    },
  );
}

class _FixedFilter extends TaskFilterNotifier {
  _FixedFilter(this._value);
  final TaskFilter _value;

  @override
  TaskFilter build() => _value;
}
