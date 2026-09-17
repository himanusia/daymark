/// A locally stored ItsTheDay event.
///
/// `start` is kept as a [DateTime] rather than a formatted string so that
/// comparisons retain the instant and timezone offset supplied by the caller.
class ItsTheDayEvent {
  ItsTheDayEvent({
    required this.id,
    required this.title,
    required this.start,
    this.allDay = false,
    Set<ReminderOffset> reminders = const {},
    this.source = EventSource.manual,
  }) : reminders = Set.unmodifiable(reminders);

  final String id;
  final String title;
  final DateTime start;
  final bool allDay;
  final Set<ReminderOffset> reminders;
  final EventSource source;

  /// The event's wall-clock start in the device's local timezone.
  DateTime get localStart => start.toLocal();

  /// The local midnight used for calendar-day comparisons.
  DateTime get localDate =>
      DateTime(localStart.year, localStart.month, localStart.day);

  ItsTheDayEvent copyWith({
    String? id,
    String? title,
    DateTime? start,
    bool? allDay,
    Set<ReminderOffset>? reminders,
    EventSource? source,
  }) {
    return ItsTheDayEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      allDay: allDay ?? this.allDay,
      reminders: reminders ?? this.reminders,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start.toIso8601String(),
      'allDay': allDay,
      'reminders': reminders.map((offset) => offset.name).toList(),
      'source': source.name,
    };
  }

  factory ItsTheDayEvent.fromJson(Map<String, dynamic> json) {
    final rawReminders = json['reminders'];
    final reminderValues = rawReminders is List
        ? rawReminders.whereType<String>()
        : const <String>[];

    return ItsTheDayEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      start: DateTime.parse(json['start'] as String),
      allDay: json['allDay'] as bool? ?? false,
      reminders: {
        for (final value in reminderValues)
          for (final offset in ReminderOffset.values)
            if (offset.name == value) offset,
      },
      source: EventSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => EventSource.manual,
      ),
    );
  }

  /// A useful first-run mark. It is only used when the store has never held
  /// data; saving an empty list prevents this demo from returning after delete.
  factory ItsTheDayEvent.demo(DateTime now) {
    final localNow = now.toLocal();
    return ItsTheDayEvent(
      id: 'demo-welcome',
      title: 'A quiet weekend reset',
      start: DateTime(localNow.year, localNow.month, localNow.day + 3, 9),
      reminders: const {ReminderOffset.h1},
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ItsTheDayEvent &&
        other.id == id &&
        other.title == title &&
        other.start == start &&
        other.allDay == allDay &&
        other.reminders.length == reminders.length &&
        other.reminders.containsAll(reminders) &&
        other.source == source;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, start, allDay, Object.hashAll(reminders), source);
}

enum EventSource { manual, calendar, google }

/// The four reminder choices in the ItsTheDay MVP.
enum ReminderOffset {
  h7(7, 'H-7', '7 days before'),
  h3(3, 'H-3', '3 days before'),
  h1(1, 'H-1', '1 day before'),
  h0(0, 'H-0', 'At start');

  const ReminderOffset(this.daysBefore, this.label, this.description);

  final int daysBefore;
  final String label;
  final String description;

  Duration get duration => Duration(days: daysBefore);
}
