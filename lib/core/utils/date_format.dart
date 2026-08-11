import 'package:intl/intl.dart';

abstract final class DateLabels {
  static String dueLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    final days = target.difference(today).inDays;
    final time = _hasTime(due) ? ', ${DateFormat.jm().format(due)}' : '';

    return switch (days) {
      0 => 'Today$time',
      1 => 'Tomorrow$time',
      -1 => 'Yesterday$time',
      < 0 when days > -7 => '${-days} days ago',
      > 0 when days < 7 => '${DateFormat.EEEE().format(due)}$time',
      _ when due.year == now.year => '${DateFormat.MMMd().format(due)}$time',
      _ => '${DateFormat.yMMMd().format(due)}$time',
    };
  }

  static String fullLabel(DateTime due) {
    final date = DateFormat.yMMMEd().format(due);
    return _hasTime(due) ? '$date at ${DateFormat.jm().format(due)}' : date;
  }

  static String timeLabel(DateTime due) => DateFormat.jm().format(due);

  static bool _hasTime(DateTime d) => d.hour != 0 || d.minute != 0;
}

abstract final class ReminderLabels {
  static const List<int> offsets = <int>[0, 10, 60, 1440];

  static String label(int minutes) => switch (minutes) {
    0 => 'At time',
    10 => '10 min before',
    60 => '1 hour before',
    1440 => '1 day before',
    _ when minutes % 1440 == 0 => '${minutes ~/ 1440} days before',
    _ when minutes % 60 == 0 => '${minutes ~/ 60} hours before',
    _ => '$minutes min before',
  };

  static String shortLabel(int minutes) => switch (minutes) {
    0 => 'On time',
    10 => '10m',
    60 => '1h',
    1440 => '1d',
    _ when minutes % 1440 == 0 => '${minutes ~/ 1440}d',
    _ when minutes % 60 == 0 => '${minutes ~/ 60}h',
    _ => '${minutes}m',
  };
}
