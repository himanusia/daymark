import 'package:flutter/services.dart';

import 'platform_interfaces.dart';

class AndroidCalendarGateway implements CalendarGateway {
  AndroidCalendarGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('daymark/calendar');

  final MethodChannel _channel;

  @override
  Future<CalendarResult> getUpcomingEvents() async {
    try {
      final permission = await _channel.invokeMethod<String>(
        'requestReadCalendar',
      );
      if (permission != 'granted') {
        return const CalendarResult.denied(
          'Calendar access was not granted. You can try again any time.',
        );
      }

      final now = DateTime.now();
      final raw = await _channel.invokeMethod<Object?>(
        'getUpcomingCalendarEvents',
        {
          'fromMillis': now.millisecondsSinceEpoch,
          'toMillis': now.add(const Duration(days: 365)).millisecondsSinceEpoch,
        },
      );
      if (raw is! List) {
        return const CalendarResult.error(
          'The calendar returned an invalid response.',
        );
      }

      final events = <ImportedCalendarEvent>[];
      for (final value in raw) {
        if (value is! Map) continue;
        final map = Map<String, dynamic>.from(value);
        final sourceId = map['id']?.toString();
        final title = map['title']?.toString().trim();
        final startMillis = _asInt(map['startMillis']);
        final endMillis = _asInt(map['endMillis']);
        if (sourceId == null ||
            title == null ||
            title.isEmpty ||
            startMillis == null) {
          continue;
        }
        final start = DateTime.fromMillisecondsSinceEpoch(startMillis);
        final end = DateTime.fromMillisecondsSinceEpoch(
          endMillis ?? startMillis,
        );
        events.add(
          ImportedCalendarEvent(
            sourceId: sourceId,
            title: title,
            start: start,
            end: end,
            allDay: map['allDay'] == true,
            location: _asText(map['location']),
            calendarName: _asText(map['calendarName']),
          ),
        );
      }
      events.sort((a, b) => a.start.compareTo(b.start));
      return CalendarResult.granted(events);
    } on MissingPluginException {
      return const CalendarResult.unavailable(
        'Calendar import is not available on this platform.',
      );
    } on PlatformException catch (error) {
      return CalendarResult.error(
        error.message ?? 'Could not read the calendar.',
      );
    } on Object {
      return const CalendarResult.error('Could not read the calendar.');
    }
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _asText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
