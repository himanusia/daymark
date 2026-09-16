import 'jelara_event.dart';

/// The semantic state of an event at a given instant.
enum CountdownStatus { upcoming, today, overdue }

class CountdownSnapshot {
  const CountdownSnapshot({
    required this.status,
    required this.calendarDays,
    required this.remaining,
    required this.isAllDay,
    required this.displayText,
    required this.accessibleLabel,
  });

  final CountdownStatus status;

  /// Signed calendar-day distance. Future dates are positive, past dates are
  /// negative, and the value is zero on the event's local calendar date.
  final int calendarDays;
  final Duration remaining;
  final bool isAllDay;
  final String displayText;
  final String accessibleLabel;

  bool get isUpcoming => status == CountdownStatus.upcoming;
  bool get isToday => status == CountdownStatus.today;
  bool get isOverdue => status == CountdownStatus.overdue;

  String get statusLabel {
    switch (status) {
      case CountdownStatus.upcoming:
        return 'UPCOMING';
      case CountdownStatus.today:
        return 'TODAY';
      case CountdownStatus.overdue:
        return 'OVERDUE';
    }
  }
}

class CountdownCalculator {
  const CountdownCalculator._();

  static CountdownSnapshot calculate(JelaraEvent event, DateTime now) {
    final localNow = now.toLocal();
    final localStart = event.localStart;
    final nowDate = DateTime(localNow.year, localNow.month, localNow.day);
    final eventDate = DateTime(
      localStart.year,
      localStart.month,
      localStart.day,
    );
    final calendarDays = eventDate.difference(nowDate).inDays;
    final remaining = localStart.difference(localNow);

    final status = event.allDay
        ? _statusForAllDay(calendarDays)
        : _statusForTimed(localStart, localNow, calendarDays);

    final displayText = _displayText(
      status: status,
      calendarDays: calendarDays,
      remaining: remaining,
      isAllDay: event.allDay,
    );

    return CountdownSnapshot(
      status: status,
      calendarDays: calendarDays,
      remaining: remaining,
      isAllDay: event.allDay,
      displayText: displayText,
      accessibleLabel: _accessibleLabel(
        event.title,
        status,
        calendarDays,
        displayText,
        event.allDay,
      ),
    );
  }

  static CountdownStatus _statusForAllDay(int calendarDays) {
    if (calendarDays > 0) return CountdownStatus.upcoming;
    if (calendarDays == 0) return CountdownStatus.today;
    return CountdownStatus.overdue;
  }

  static CountdownStatus _statusForTimed(
    DateTime eventStart,
    DateTime now,
    int calendarDays,
  ) {
    if (eventStart.isBefore(now)) return CountdownStatus.overdue;
    if (calendarDays == 0) return CountdownStatus.today;
    return CountdownStatus.upcoming;
  }

  static String _displayText({
    required CountdownStatus status,
    required int calendarDays,
    required Duration remaining,
    required bool isAllDay,
  }) {
    if (isAllDay) {
      if (status == CountdownStatus.today) return 'D-DAY';
      if (status == CountdownStatus.overdue) {
        return 'D+${calendarDays.abs()}';
      }
      return 'D-$calendarDays';
    }

    if (status == CountdownStatus.overdue) {
      return 'D+${calendarDays.abs()}';
    }

    final totalSeconds = remaining.inSeconds;
    if (totalSeconds < Duration.secondsPerDay && totalSeconds >= 0) {
      final hours = totalSeconds ~/ Duration.secondsPerHour;
      final minutes =
          (totalSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
      final seconds = totalSeconds % Duration.secondsPerMinute;
      return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
    }

    final days = totalSeconds ~/ Duration.secondsPerDay;
    final hours =
        (totalSeconds % Duration.secondsPerDay) ~/ Duration.secondsPerHour;
    return '${days}d ${_twoDigits(hours)}h';
  }

  static String _accessibleLabel(
    String title,
    CountdownStatus status,
    int calendarDays,
    String displayText,
    bool isAllDay,
  ) {
    switch (status) {
      case CountdownStatus.today:
        return isAllDay
            ? '$title, today'
            : '$title, today, $displayText remaining';
      case CountdownStatus.upcoming:
        return isAllDay
            ? '$title, in $calendarDays ${_plural(calendarDays, 'day')}'
            : '$title, $displayText remaining';
      case CountdownStatus.overdue:
        final days = calendarDays.abs();
        return '$title, overdue by $days ${_plural(days, 'day')}';
    }
  }

  static String _plural(int value, String singular) {
    return value == 1 ? singular : '${singular}s';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
