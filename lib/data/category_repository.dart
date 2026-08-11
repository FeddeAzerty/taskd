import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/task_category.dart';

class CategoryRepository {
  CategoryRepository(this._box);

  final Box<TaskCategory> _box;
  static const _uuid = Uuid();

  List<TaskCategory> getAll() {
    final all = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(all);
  }

  TaskCategory? getById(String? id) => id == null ? null : _box.get(id);

  Stream<BoxEvent> watch() => _box.watch();

  Future<TaskCategory> create({
    required String name,
    required int colorValue,
    required int iconIndex,
  }) async {
    final category = TaskCategory(
      id: _uuid.v4(),
      name: name.trim(),
      colorValue: colorValue,
      iconIndex: iconIndex,
      createdAt: DateTime.now(),
    );
    await _box.put(category.id, category);
    return category;
  }

  Future<void> update(TaskCategory category) => _box.put(category.id, category);

  Future<void> delete(String id) => _box.delete(id);
}
