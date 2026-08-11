import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../core/notifications/notification_service.dart';
import '../data/category_repository.dart';
import '../data/hive_init.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import '../models/task_category.dart';

final taskBoxProvider = Provider<Box<Task>>(
  (ref) => Hive.box<Task>(HiveBoxes.tasks),
);

final categoryBoxProvider = Provider<Box<TaskCategory>>(
  (ref) => Hive.box<TaskCategory>(HiveBoxes.categories),
);

final settingsBoxProvider = Provider<Box<dynamic>>(
  (ref) => Hive.box<dynamic>(HiveBoxes.settings),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(taskBoxProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(categoryBoxProvider)),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);
