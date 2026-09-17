import 'package:flutter/foundation.dart';

import '../data/event_repository.dart';
import '../domain/countdown.dart';
import '../domain/itstheday_event.dart';
import '../platform/google_calendar_gateway.dart';
import '../platform/platform_interfaces.dart';

class SaveEventResult {
  const SaveEventResult({
    this.notificationPermission,
    this.notificationsSynced = false,
    this.warning,
  });

  final NotificationPermissionStatus? notificationPermission;
  final bool notificationsSynced;
  final String? warning;
}

/// Coordinates local data and platform ports without exposing Android APIs to
/// the widgets. All time-dependent work takes a clock so it remains testable.
class ItsTheDayController extends ChangeNotifier {
  ItsTheDayController({
    required EventRepository repository,
    required CalendarGateway calendar,
    required WidgetGateway widget,
    required ReminderGateway reminders,
    GoogleCalendarGateway googleCalendar =
        const UnsupportedGoogleCalendarGateway(),
    DateTime Function()? clock,
  }) : _repository = repository,
       _calendar = calendar,
       _widget = widget,
       _reminders = reminders,
       _googleCalendar = googleCalendar,
       _clock = clock ?? DateTime.now;

  final EventRepository _repository;
  final CalendarGateway _calendar;
  final WidgetGateway _widget;
  final ReminderGateway _reminders;
  final GoogleCalendarGateway _googleCalendar;
  final DateTime Function() _clock;

  List<ItsTheDayEvent> _events = const [];
  String? _selectedId;
  GoogleCalendarAccount? _googleCalendarAccount;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  List<ItsTheDayEvent> get events => List.unmodifiable(_events);

  ItsTheDayEvent? get selectedEvent {
    for (final event in _events) {
      if (event.id == _selectedId) return event;
    }
    return _events.isEmpty ? null : _events.first;
  }

  String? get selectedId => selectedEvent?.id;

  CalendarGateway get calendarGateway => _calendar;

  GoogleCalendarGateway get googleCalendarGateway => _googleCalendar;

  GoogleCalendarAccount? get googleCalendarAccount =>
      _googleCalendarAccount ?? _googleCalendar.currentAccount;

  bool get googleCalendarConfigured => _googleCalendar.isConfigured;

  Future<void> initialize() async {
    if (_initialized) return;
    final stored = await _repository.read();
    final loaded = List<ItsTheDayEvent>.of(stored.events);
    if (!stored.hasStoredData) {
      final demo = ItsTheDayEvent.demo(_clock());
      loaded.add(demo);
      _selectedId = demo.id;
      _events = _sortEvents(loaded);
      await _repository.write(events: _events, selectedId: _selectedId);
    } else {
      _events = _sortEvents(loaded);
      _selectedId = _validSelection(stored.selectedId);
      if (_selectedId == null && _events.isNotEmpty) {
        _selectedId = _events.first.id;
        await _repository.write(events: _events, selectedId: _selectedId);
      }
    }
    try {
      _googleCalendarAccount = await _googleCalendar.restore();
    } on Object {
      _googleCalendarAccount = null;
    }
    _initialized = true;
    notifyListeners();
    await _syncWidget();
  }

  CountdownSnapshot countdownFor(ItsTheDayEvent event) {
    return CountdownCalculator.calculate(event, _clock());
  }

  Future<SaveEventResult> saveEvent(ItsTheDayEvent event) async {
    final existing = _find(event.id);
    String? warning;
    NotificationPermissionStatus? permission;
    var notificationsSynced = false;

    // Cancel first so changing a title, time, or offset never leaves an old
    // notification scheduled under the same event id.
    try {
      await _reminders.cancelEvent(event.id);
      if (event.reminders.isNotEmpty) {
        permission = await _reminders.requestPermission();
        if (permission == NotificationPermissionStatus.granted) {
          await _reminders.sync(event, now: _clock());
          notificationsSynced = true;
        }
      }
    } on Object catch (error) {
      warning = 'Reminder sync failed: $error';
    }

    final next = List<ItsTheDayEvent>.of(_events);
    if (existing == null) {
      next.add(event);
    } else {
      final index = next.indexWhere((item) => item.id == event.id);
      next[index] = event;
    }
    _events = _sortEvents(next);
    _selectedId = event.id;
    await _repository.write(events: _events, selectedId: _selectedId);
    notifyListeners();
    await _syncWidget();

    return SaveEventResult(
      notificationPermission: permission,
      notificationsSynced: notificationsSynced,
      warning: warning,
    );
  }

  Future<void> deleteEvent(String eventId) async {
    await _reminders.cancelEvent(eventId);
    _events = _events.where((event) => event.id != eventId).toList();
    if (_selectedId == eventId) {
      _selectedId = _events.isEmpty ? null : _events.first.id;
    }
    await _repository.write(events: _events, selectedId: _selectedId);
    notifyListeners();
    await _syncWidget();
  }

  Future<void> selectEvent(String eventId) async {
    if (_find(eventId) == null || eventId == _selectedId) return;
    _selectedId = eventId;
    await _repository.write(events: _events, selectedId: _selectedId);
    notifyListeners();
    await _syncWidget();
  }

  Future<CalendarResult> getUpcomingCalendarEvents() {
    return _calendar.getUpcomingEvents();
  }

  Future<CalendarResult> getUpcomingGoogleCalendarEvents() {
    return _googleCalendar.getUpcomingEvents();
  }

  Future<GoogleCalendarAccount> connectGoogleCalendar() async {
    final account = await _googleCalendar.signIn();
    _googleCalendarAccount = account;
    notifyListeners();
    return account;
  }

  Future<void> disconnectGoogleCalendar() async {
    await _googleCalendar.signOut();
    _googleCalendarAccount = null;
    notifyListeners();
  }

  /// Allows the home screen to repaint after its foreground timer ticks.
  void refreshCountdown() => notifyListeners();

  ItsTheDayEvent? _find(String id) {
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
  }

  String? _validSelection(String? candidate) {
    if (candidate == null) return null;
    return _find(candidate) == null ? null : candidate;
  }

  List<ItsTheDayEvent> _sortEvents(Iterable<ItsTheDayEvent> events) {
    final result = List<ItsTheDayEvent>.of(events);
    result.sort((a, b) => a.localStart.compareTo(b.localStart));
    return result;
  }

  Future<void> _syncWidget() async {
    final event = selectedEvent;
    try {
      if (event == null) {
        await _widget.clear();
      } else {
        await _widget.update(event, countdownFor(event));
      }
    } on Object {
      // A missing widget host must not make local event editing fail.
    }
  }
}
