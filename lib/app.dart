import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/filter_providers.dart';
import 'providers/repository_providers.dart';
import 'providers/task_providers.dart';
import 'screens/task_list_screen.dart';

class TaskdApp extends ConsumerStatefulWidget {
  const TaskdApp({super.key});

  @override
  ConsumerState<TaskdApp> createState() => _TaskdAppState();
}

class _TaskdAppState extends ConsumerState<TaskdApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(notificationServiceProvider).requestPermissions();
      if (!mounted) return;
      await ref.read(taskListProvider.notifier).resyncAllReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Taskd',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const TaskListScreen(),
    );
  }
}
