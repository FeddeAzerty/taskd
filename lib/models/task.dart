import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  Task({
    required this.id,
    required this.title,
    required this.createdAt,
    this.notes,
    this.isCompleted = false,
    this.completedAt,
    this.dueDate,
    this.categoryId,
    this.reminderMinutesBefore,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? notes;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? completedAt;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final String? categoryId;

  @HiveField(8)
  final int? reminderMinutesBefore;

  DateTime? get reminderTime {
    final due = dueDate;
    final offset = reminderMinutesBefore;
    if (due == null || offset == null) return null;
    return due.subtract(Duration(minutes: offset));
  }

  bool get hasSchedulableReminder {
    final time = reminderTime;
    return !isCompleted && time != null && time.isAfter(DateTime.now());
  }

  bool get isOverdue {
    final due = dueDate;
    if (due == null || isCompleted) return false;
    return due.isBefore(DateTime.now());
  }

  int get notificationId => id.hashCode & 0x7FFFFFFF;

  Task copyWith({
    String? title,
    String? notes,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? dueDate,
    String? categoryId,
    int? reminderMinutesBefore,
    bool clearNotes = false,
    bool clearDueDate = false,
    bool clearCategory = false,
    bool clearReminder = false,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      reminderMinutesBefore: (clearReminder || clearDueDate)
          ? null
          : (reminderMinutesBefore ?? this.reminderMinutesBefore),
    );
  }

  @override
  String toString() => 'Task($id, "$title", done: $isCompleted)';
}
