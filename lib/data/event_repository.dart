import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daymark_event.dart';

class EventStore {
  const EventStore({
    required this.events,
    required this.selectedId,
    required this.hasStoredData,
  });

  final List<DaymarkEvent> events;
  final String? selectedId;
  final bool hasStoredData;
}

abstract interface class EventRepository {
  Future<EventStore> read();

  Future<void> write({
    required List<DaymarkEvent> events,
    required String? selectedId,
  });
}

class SharedPreferencesEventRepository implements EventRepository {
  SharedPreferencesEventRepository({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const storageKey = 'daymark.event_store.v1';

  final Future<SharedPreferences> Function() _preferencesLoader;

  @override
  Future<EventStore> read() async {
    final preferences = await _preferencesLoader();
    final encoded = preferences.getString(storageKey);
    if (encoded == null) {
      return const EventStore(
        events: <DaymarkEvent>[],
        selectedId: null,
        hasStoredData: false,
      );
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        return const EventStore(
          events: <DaymarkEvent>[],
          selectedId: null,
          hasStoredData: true,
        );
      }
      final rawEvents = decoded['events'];
      final events = <DaymarkEvent>[];
      if (rawEvents is List) {
        for (final rawEvent in rawEvents) {
          if (rawEvent is! Map) continue;
          try {
            events.add(
              DaymarkEvent.fromJson(Map<String, dynamic>.from(rawEvent)),
            );
          } on Object {
            // Keep the rest of the user's events if one old record is bad.
          }
        }
      }
      return EventStore(
        events: List.unmodifiable(events),
        selectedId: decoded['selectedId'] as String?,
        hasStoredData: true,
      );
    } on Object {
      // Treat malformed local data as an empty, already-initialized store.
      // This avoids resurrecting the demo after the user has created data.
      return const EventStore(
        events: <DaymarkEvent>[],
        selectedId: null,
        hasStoredData: true,
      );
    }
  }

  @override
  Future<void> write({
    required List<DaymarkEvent> events,
    required String? selectedId,
  }) async {
    final preferences = await _preferencesLoader();
    await preferences.setString(
      storageKey,
      jsonEncode({
        'events': events.map((event) => event.toJson()).toList(),
        'selectedId': selectedId,
      }),
    );
  }
}

/// A deterministic repository for app/widget tests and non-Android previews.
class MemoryEventRepository implements EventRepository {
  MemoryEventRepository({
    List<DaymarkEvent> events = const [],
    String? selectedId,
    bool hasStoredData = true,
  }) : _events = List.of(events),
       _selectedId = selectedId,
       _hasStoredData = hasStoredData;

  List<DaymarkEvent> _events;
  String? _selectedId;
  bool _hasStoredData;

  @override
  Future<EventStore> read() async => EventStore(
    events: List.unmodifiable(_events),
    selectedId: _selectedId,
    hasStoredData: _hasStoredData,
  );

  @override
  Future<void> write({
    required List<DaymarkEvent> events,
    required String? selectedId,
  }) async {
    _events = List.of(events);
    _selectedId = selectedId;
    _hasStoredData = true;
  }
}
