import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/task_category.dart';

abstract final class HiveBoxes {
  static const String tasks = 'tasks';
  static const String categories = 'categories';
  static const String settings = 'settings';
}

abstract final class SettingsKeys {
  static const String themeMode = 'themeMode';
  static const String sortOption = 'sortOption';
  static const String seeded = 'seeded';
}

Future<void> initHive() async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TaskCategoryAdapter());

  await Future.wait([
    Hive.openBox<Task>(HiveBoxes.tasks),
    Hive.openBox<TaskCategory>(HiveBoxes.categories),
    Hive.openBox<dynamic>(HiveBoxes.settings),
  ]);

  await _seedDefaultCategories();
}

Future<void> _seedDefaultCategories() async {
  final settings = Hive.box<dynamic>(HiveBoxes.settings);
  if (settings.get(SettingsKeys.seeded) == true) return;

  final categories = Hive.box<TaskCategory>(HiveBoxes.categories);
  const uuid = Uuid();
  final now = DateTime.now();

  const defaults = <({String name, int color, int icon})>[
    (name: 'Personal', color: 0xFF4F86F7, icon: 2),
    (name: 'Work', color: 0xFF34C77B, icon: 1),
    (name: 'Errands', color: 0xFFF2A73B, icon: 3),
  ];

  for (final (index, d) in defaults.indexed) {
    final id = uuid.v4();
    await categories.put(
      id,
      TaskCategory(
        id: id,
        name: d.name,
        colorValue: d.color,
        iconIndex: d.icon,
        createdAt: now.add(Duration(milliseconds: index)),
      ),
    );
  }

  await settings.put(SettingsKeys.seeded, true);
}
