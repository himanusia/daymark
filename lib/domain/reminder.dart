import 'itstheday_event.dart';

class ScheduledReminder {
  const ScheduledReminder({required this.offset, required this.at});

  final ReminderOffset offset;
  final DateTime at;
}

class ReminderSchedule {
  const ReminderSchedule._();

  /// Returns future reminders in a stable H-7, H-3, H-1, H-0 order.
  ///
  /// All-day events use local midnight as their deterministic anchor. The
  /// caller supplies [now] so this logic is pure and easy to test.
  static List<ScheduledReminder> forEvent(
    ItsTheDayEvent event, {
    required DateTime now,
  }) {
    final localStart = event.localStart;
    final anchor = event.allDay
        ? DateTime(localStart.year, localStart.month, localStart.day)
        : localStart;
    final localNow = now.toLocal();

    final scheduled = <ScheduledReminder>[];
    for (final offset in ReminderOffset.values) {
      if (!event.reminders.contains(offset)) continue;
      final at = anchor.subtract(offset.duration);
      if (at.isAfter(localNow)) {
        scheduled.add(ScheduledReminder(offset: offset, at: at));
      }
    }
    return scheduled;
  }
}
