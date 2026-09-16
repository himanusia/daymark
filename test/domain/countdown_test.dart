import 'package:flutter_test/flutter_test.dart';

import 'package:daymark/domain/countdown.dart';
import 'package:daymark/domain/daymark_event.dart';

void main() {
  group('CountdownCalculator', () {
    test('counts calendar days for an all-day event', () {
      final event = DaymarkEvent(
        id: 'launch',
        title: 'Product launch',
        start: DateTime(2026, 9, 20),
        allDay: true,
      );

      final snapshot = CountdownCalculator.calculate(
        event,
        DateTime(2026, 9, 16, 21, 15),
      );

      expect(snapshot.status, CountdownStatus.upcoming);
      expect(snapshot.calendarDays, 4);
      expect(snapshot.displayText, 'D-4');
      expect(snapshot.isAllDay, isTrue);
    });

    test('uses a clock countdown for a timed event happening today', () {
      final event = DaymarkEvent(
        id: 'dentist',
        title: 'Dentist',
        start: DateTime(2026, 9, 16, 14, 30),
        allDay: false,
      );

      final snapshot = CountdownCalculator.calculate(
        event,
        DateTime(2026, 9, 16, 9),
      );

      expect(snapshot.status, CountdownStatus.today);
      expect(snapshot.calendarDays, 0);
      expect(snapshot.displayText, '05:30:00');
      expect(snapshot.remaining, const Duration(hours: 5, minutes: 30));
      expect(snapshot.isAllDay, isFalse);
    });

    test('marks a timed event overdue after its start time', () {
      final event = DaymarkEvent(
        id: 'review',
        title: 'Design review',
        start: DateTime(2026, 9, 16, 8, 30),
        allDay: false,
      );

      final snapshot = CountdownCalculator.calculate(
        event,
        DateTime(2026, 9, 16, 10),
      );

      expect(snapshot.status, CountdownStatus.overdue);
      expect(snapshot.calendarDays, 0);
      expect(snapshot.displayText, 'D+0');
      expect(snapshot.remaining, const Duration(hours: -1, minutes: -30));
    });

    test('marks yesterday all-day events overdue by calendar day', () {
      final event = DaymarkEvent(
        id: 'birthday',
        title: 'Birthday',
        start: DateTime(2026, 9, 15),
        allDay: true,
      );

      final snapshot = CountdownCalculator.calculate(
        event,
        DateTime(2026, 9, 16, 0, 1),
      );

      expect(snapshot.status, CountdownStatus.overdue);
      expect(snapshot.calendarDays, -1);
      expect(snapshot.displayText, 'D+1');
    });

    test('formats an all-day event today as D-DAY instead of hours', () {
      final event = DaymarkEvent(
        id: 'today',
        title: 'Today',
        start: DateTime(2026, 9, 16),
        allDay: true,
      );

      final snapshot = CountdownCalculator.calculate(
        event,
        DateTime(2026, 9, 16, 23, 59),
      );

      expect(snapshot.status, CountdownStatus.today);
      expect(snapshot.displayText, 'D-DAY');
      expect(snapshot.accessibleLabel, contains('today'));
    });
  });
}
