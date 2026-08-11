import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_init.dart';
import '../models/task_filter.dart';
import 'repository_providers.dart';

class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  void setStatus(TaskStatusFilter status) =>
      state = state.copyWith(status: status);

  void toggleCategory(String categoryId) {
    state = state.categoryId == categoryId
        ? state.copyWith(clearCategory: true)
        : state.copyWith(categoryId: categoryId);
  }

  void clearCategory() => state = state.copyWith(clearCategory: true);

  void setDueDate(DueDateFilter dueDate) =>
      state = state.copyWith(dueDate: dueDate);

  void setQuery(String query) => state = state.copyWith(query: query);

  void clearRefinements() => state = TaskFilter(status: state.status);
}

final taskFilterProvider = NotifierProvider<TaskFilterNotifier, TaskFilter>(
  TaskFilterNotifier.new,
);

class SortOptionNotifier extends Notifier<SortOption> {
  @override
  SortOption build() {
    final stored = ref.read(settingsBoxProvider).get(SettingsKeys.sortOption);
    return _decode(stored);
  }

  Future<void> set(SortOption option) async {
    state = option;
    await ref
        .read(settingsBoxProvider)
        .put(SettingsKeys.sortOption, option.name);
  }

  static SortOption _decode(Object? stored) {
    if (stored is! String) return SortOption.dueDateAsc;
    for (final option in SortOption.values) {
      if (option.name == stored) return option;
    }
    return SortOption.dueDateAsc;
  }
}

final sortOptionProvider = NotifierProvider<SortOptionNotifier, SortOption>(
  SortOptionNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref.read(settingsBoxProvider).get(SettingsKeys.themeMode);
    return _decode(stored);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsBoxProvider).put(SettingsKeys.themeMode, mode.name);
  }

  Future<void> cycle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await set(next);
  }

  static ThemeMode _decode(Object? stored) {
    if (stored is! String) return ThemeMode.system;
    for (final mode in ThemeMode.values) {
      if (mode.name == stored) return mode;
    }
    return ThemeMode.system;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
