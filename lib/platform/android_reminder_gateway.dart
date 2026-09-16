import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/daymark_event.dart';
import '../domain/reminder.dart';
import 'platform_interfaces.dart';

class AndroidReminderGateway implements ReminderGateway {
  AndroidReminderGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'daymark_reminders';
  static const _channelName = 'Daymark reminders';
  static const _channelDescription = 'Reminders for your saved marks';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.defaultImportance,
          ),
        );
    _initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    try {
      await _initialize();
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted == true
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    } on Object {
      return NotificationPermissionStatus.unavailable;
    }
  }

  @override
  Future<void> sync(DaymarkEvent event, {required DateTime now}) async {
    await _initialize();
    await cancelEvent(event.id);
    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );

    for (final reminder in ReminderSchedule.forEvent(event, now: now)) {
      final scheduledDate = tz.TZDateTime.from(reminder.at, tz.local);
      await _plugin.zonedSchedule(
        id: notificationId(event.id, reminder.offset),
        title: '${reminder.offset.label} · ${event.title}',
        body: reminder.offset == ReminderOffset.h0
            ? '${event.title} starts now.'
            : '${event.title} starts in ${reminder.offset.daysBefore} '
                  '${reminder.offset.daysBefore == 1 ? 'day' : 'days'}.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: event.id,
      );
    }
  }

  @override
  Future<void> cancelEvent(String eventId) async {
    await _initialize();
    for (final offset in ReminderOffset.values) {
      await _plugin.cancel(id: notificationId(eventId, offset));
    }
  }

  /// Stable positive IDs let an edit replace the old schedule without keeping
  /// a second notification alive. This is deliberately not Dart's hashCode,
  /// which is not a persistence contract.
  static int notificationId(String eventId, ReminderOffset offset) {
    var hash = 0x811c9dc5;
    for (final codeUnit in eventId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    hash ^= offset.index + 1;
    hash &= 0x7fffffff;
    return hash == 0 ? 1 : hash;
  }
}
