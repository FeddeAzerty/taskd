import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task_category.g.dart';

@HiveType(typeId: 1)
class TaskCategory extends HiveObject {
  TaskCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconIndex,
    required this.createdAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final int iconIndex;

  @HiveField(4)
  final DateTime createdAt;

  Color get color => Color(colorValue);

  IconData get icon =>
      categoryIcons[iconIndex.clamp(0, categoryIcons.length - 1)];

  TaskCategory copyWith({String? name, int? colorValue, int? iconIndex}) {
    return TaskCategory(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconIndex: iconIndex ?? this.iconIndex,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'TaskCategory($id, $name)';
}

const List<IconData> categoryIcons = <IconData>[
  Icons.label_outline,
  Icons.work_outline,
  Icons.person_outline,
  Icons.shopping_cart_outlined,
  Icons.favorite_outline,
  Icons.school_outlined,
  Icons.home_outlined,
  Icons.fitness_center_outlined,
  Icons.attach_money_outlined,
  Icons.flight_takeoff_outlined,
  Icons.pets_outlined,
  Icons.menu_book_outlined,
  Icons.build_outlined,
  Icons.celebration_outlined,
];

const List<int> categoryColorSwatch = <int>[
  0xFF4F86F7,
  0xFF34C77B,
  0xFFF2A73B,
  0xFFE5566D,
  0xFF9B6DFF,
  0xFF20BFB8,
  0xFFF2705B,
  0xFF8E8E93,
];
