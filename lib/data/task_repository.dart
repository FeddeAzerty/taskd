import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';

class TaskRepository {
  TaskRepository(this._box);

  final Box<Task> _box;
  static const _uuid = Uuid();

  List<Task> getAll() => _box.values.toList(growable: false);

  Task? getById(String id) => _box.get(id);

  Stream<BoxEvent> watch() => _box.watch();

  Future<Task> create({
    required String title,
    String? notes,
    DateTime? dueDate,
    String? categoryId,
    int? reminderMinutesBefore,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      notes: _blankToNull(notes),
      createdAt: DateTime.now(),
      dueDate: dueDate,
      categoryId: categoryId,
      reminderMinutesBefore: dueDate == null ? null : reminderMinutesBefore,
    );
    await _box.put(task.id, task);
    return task;
  }

  Future<void> update(Task task) => _box.put(task.id, task);

  Future<void> delete(String id) => _box.delete(id);

  Future<Task> toggleComplete(Task task) async {
    final nowDone = !task.isCompleted;
    final updated = task.copyWith(
      isCompleted: nowDone,
      completedAt: nowDone ? DateTime.now() : null,
      clearCompletedAt: !nowDone,
    );
    await _box.put(updated.id, updated);
    return updated;
  }

  Future<List<String>> clearCompleted() async {
    final ids = _box.values
        .where((t) => t.isCompleted)
        .map((t) => t.id)
        .toList(growable: false);
    await _box.deleteAll(ids);
    return ids;
  }

  Future<void> detachCategory(String categoryId) async {
    final affected = _box.values.where((t) => t.categoryId == categoryId);
    final updates = <String, Task>{
      for (final t in affected) t.id: t.copyWith(clearCategory: true),
    };
    if (updates.isNotEmpty) await _box.putAll(updates);
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
