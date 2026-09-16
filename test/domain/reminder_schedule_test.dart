import 'package:flutter_test/flutter_test.dart';

import 'package:daymark/domain/daymark_event.dart';
import 'package:daymark/domain/reminder.dart';

void main() {
  group('ReminderSchedule', () {
    test('calculates selected timed reminders relative to the event time', () {
      final event = DaymarkEvent(
        id: 'flight',
        title: 'Flight',
        start: DateTime(2026, 9, 20, 12),
        allDay: false,
        reminders: const {
          ReminderOffset.h7,
          ReminderOffset.h3,
          ReminderOffset.h1,
          ReminderOffset.h0,
        },
      );

      final reminders = ReminderSchedule.forEvent(
        event,
        now: DateTime(2026, 9, 10, 12),
      );

      expect(reminders.map((reminder) => reminder.offset).toList(), [
        ReminderOffset.h7,
        ReminderOffset.h3,
        ReminderOffset.h1,
        ReminderOffset.h0,
      ]);
      expect(reminders.map((reminder) => reminder.at).toList(), [
        DateTime(2026, 9, 13, 12),
        DateTime(2026, 9, 17, 12),
        DateTime(2026, 9, 19, 12),
        DateTime(2026, 9, 20, 12),
      ]);
    });

    test('uses local midnight as the anchor for all-day reminders', () {
      final event = DaymarkEvent(
        id: 'conference',
        title: 'Conference',
        start: DateTime(2026, 9, 21),
        allDay: true,
        reminders: const {
          ReminderOffset.h7,
          ReminderOffset.h3,
          ReminderOffset.h1,
          ReminderOffset.h0,
        },
      );

      final reminders = ReminderSchedule.forEvent(
        event,
        now: DateTime(2026, 9, 10, 12),
      );

      expect(reminders.map((reminder) => reminder.at).toList(), [
        DateTime(2026, 9, 14),
        DateTime(2026, 9, 18),
        DateTime(2026, 9, 20),
        DateTime(2026, 9, 21),
      ]);
    });

    test('does not schedule reminders that are already in the past', () {
      final event = DaymarkEvent(
        id: 'past',
        title: 'Past event',
        start: DateTime(2026, 9, 20, 12),
        allDay: false,
        reminders: const {
          ReminderOffset.h7,
          ReminderOffset.h3,
          ReminderOffset.h1,
          ReminderOffset.h0,
        },
      );

      final reminders = ReminderSchedule.forEvent(
        event,
        now: DateTime(2026, 9, 20, 11, 30),
      );

      expect(reminders.map((reminder) => reminder.offset).toList(), [
        ReminderOffset.h0,
      ]);
      expect(reminders.single.at, DateTime(2026, 9, 20, 12));
    });

    test('orders reminders by their H-minus offset', () {
      final event = DaymarkEvent(
        id: 'ordered',
        title: 'Ordered',
        start: DateTime(2026, 9, 20, 12),
        allDay: false,
        reminders: const {ReminderOffset.h1, ReminderOffset.h7},
      );

      final reminders = ReminderSchedule.forEvent(
        event,
        now: DateTime(2026, 9, 10),
      );

      expect(reminders.map((reminder) => reminder.offset).toList(), [
        ReminderOffset.h7,
        ReminderOffset.h1,
      ]);
    });
  });
}
