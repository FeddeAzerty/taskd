import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/task.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux;
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'task_reminders',
        'Task reminders',
        channelDescription: 'Reminders for tasks that have a due date',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    windows: WindowsNotificationDetails(),
  );

  Future<void> init() async {
    if (_ready || !isSupported) return;

    tz_data.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      windows: WindowsInitializationSettings(
        appName: 'Taskd',
        appUserModelId: 'com.taskd.app',
        guid: '4d4a0f0c-6d29-4b52-9d0f-2f5f6f1b7a21',
      ),
    );

    try {
      await _plugin.initialize(settings: settings);
      _ready = true;
    } on Exception catch (e) {
      debugPrint(
        'NotificationService: initialisation failed ($e). '
        'Reminders are disabled for this session.',
      );
      _ready = false;
    }
  }

  Future<bool> requestPermissions() async {
    if (!_ready) return false;

    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return false;

      return await android.requestNotificationsPermission() ?? false;
    }

    return true;
  }

  Future<void> syncReminder(Task task) async {
    if (!_ready) return;

    await cancel(task.notificationId);
    if (!task.hasSchedulableReminder) return;

    final when = task.reminderTime!;

    final scheduled = tz.TZDateTime.from(when, tz.local);

    for (final mode in const [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id: task.notificationId,
          title: task.title,
          body: _bodyFor(task),
          scheduledDate: scheduled,
          notificationDetails: _details,
          androidScheduleMode: mode,
          payload: task.id,
        );
        return;
      } on Exception catch (e) {
        debugPrint(
          'NotificationService: $mode failed for "${task.title}" ($e)',
        );
      }
    }
  }

  Future<void> cancel(int notificationId) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: notificationId);
    } on Exception catch (e) {
      debugPrint('NotificationService: cancel failed ($e)');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } on Exception catch (e) {
      debugPrint('NotificationService: cancelAll failed ($e)');
    }
  }

  Future<void> rescheduleAll(List<Task> tasks) async {
    if (!_ready) return;
    await cancelAll();
    for (final task in tasks.where((t) => t.hasSchedulableReminder)) {
      await syncReminder(task);
    }
  }

  static String _bodyFor(Task task) {
    final notes = task.notes;
    if (notes != null && notes.isNotEmpty) return notes;
    return 'This task is due now.';
  }
}
