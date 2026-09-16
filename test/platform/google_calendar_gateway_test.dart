import 'package:flutter_test/flutter_test.dart';

import 'package:daymark/platform/google_calendar_gateway.dart';
import 'package:daymark/platform/platform_interfaces.dart';
import 'package:daymark/domain/daymark_event.dart';

void main() {
  test('Google Calendar parser keeps valid events in start order', () {
    final events = AndroidGoogleCalendarGateway.parseEvents({
      'items': [
        {
          'id': 'later',
          'summary': 'Later meeting',
          'start': {'dateTime': '2026-09-20T10:00:00+07:00'},
          'end': {'dateTime': '2026-09-20T11:00:00+07:00'},
          'location': 'Room B',
        },
        {
          'id': 'all-day',
          'summary': 'Release day',
          'start': {'date': '2026-09-19'},
          'end': {'date': '2026-09-20'},
        },
        {
          'id': 'cancelled',
          'summary': 'Do not import',
          'status': 'cancelled',
          'start': {'date': '2026-09-18'},
          'end': {'date': '2026-09-19'},
        },
        {
          'id': 'blank',
          'summary': '   ',
          'start': {'date': '2026-09-17'},
          'end': {'date': '2026-09-18'},
        },
        {
          'id': 'broken',
          'summary': 'Broken row',
          'start': {'dateTime': 'not-a-date'},
          'end': {'dateTime': '2026-09-21T11:00:00+07:00'},
        },
      ],
    });

    expect(events, hasLength(2));
    expect(events.first.sourceId, 'all-day');
    expect(events.first.allDay, isTrue);
    expect(events.first.provider, CalendarProvider.google);
    expect(events.first.toDaymarkEvent().source, EventSource.google);
    expect(events.last.title, 'Later meeting');
    expect(events.last.location, 'Room B');
    expect(events.last.calendarName, 'Google Calendar');
  });

  test('Google gateway reports missing build-time OAuth configuration', () {
    final gateway = AndroidGoogleCalendarGateway(serverClientId: '');

    expect(gateway.isConfigured, isFalse);
    expect(gateway.currentAccount, isNull);
  });
}
