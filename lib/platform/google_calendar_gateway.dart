import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'platform_interfaces.dart';

const String googleCalendarReadOnlyScope =
    'https://www.googleapis.com/auth/calendar.readonly';

class GoogleCalendarSetupException implements Exception {
  const GoogleCalendarSetupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Read-only Google Calendar connection used by the Android import flow.
///
/// Google Sign-In owns the account/session tokens. This adapter only keeps the
/// in-memory account handle while the process is alive; no access or refresh
/// token is written to shared preferences.
class AndroidGoogleCalendarGateway implements GoogleCalendarGateway {
  AndroidGoogleCalendarGateway({
    String? serverClientId,
    http.Client? client,
    GoogleSignIn? signIn,
  }) : _serverClientId =
           serverClientId ??
           const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
       _client = client ?? http.Client(),
       _signIn = signIn ?? GoogleSignIn.instance;

  final String _serverClientId;
  final http.Client _client;
  final GoogleSignIn _signIn;
  GoogleSignInAccount? _googleAccount;
  bool _initialized = false;

  @override
  bool get isConfigured => _serverClientId.trim().isNotEmpty;

  @override
  GoogleCalendarAccount? get currentAccount {
    final account = _googleAccount;
    if (account == null) return null;
    return GoogleCalendarAccount(
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    if (!isConfigured) {
      _initialized = true;
      return;
    }
    await _signIn.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  @override
  Future<GoogleCalendarAccount?> restore() async {
    if (!isConfigured) return null;
    await initialize();
    final attempt = _signIn.attemptLightweightAuthentication();
    if (attempt == null) return null;
    try {
      final account = await attempt;
      _googleAccount = account;
      return currentAccount;
    } on GoogleSignInException catch (error) {
      // A stale local Google session must not prevent the countdown app from
      // opening. The next explicit tap can start a fresh sign-in.
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted ||
          error.code == GoogleSignInExceptionCode.uiUnavailable) {
        return null;
      }
      return null;
    }
  }

  @override
  Future<GoogleCalendarAccount> signIn() async {
    if (!isConfigured) {
      throw const GoogleCalendarSetupException(
        'Google Calendar login needs a web OAuth client ID. '
        'Build with --dart-define=GOOGLE_SERVER_CLIENT_ID=...',
      );
    }
    await initialize();
    final account = await _signIn.authenticate();
    await account.authorizationClient.authorizeScopes(const <String>[
      googleCalendarReadOnlyScope,
    ]);
    _googleAccount = account;
    return currentAccount!;
  }

  @override
  Future<void> signOut() async {
    _googleAccount = null;
    if (_initialized) await _signIn.signOut();
  }

  @override
  Future<CalendarResult> getUpcomingEvents() async {
    if (!isConfigured) {
      return const CalendarResult.unavailable(
        'Google Calendar login is not configured for this build.',
      );
    }
    final account = _googleAccount;
    if (account == null) {
      return const CalendarResult.denied(
        'Connect a Google account to read its calendar.',
      );
    }

    try {
      final headers = await account.authorizationClient.authorizationHeaders(
        const <String>[googleCalendarReadOnlyScope],
        promptIfNecessary: true,
      );
      if (headers == null) {
        return const CalendarResult.denied(
          'Google Calendar permission was not granted.',
        );
      }

      final now = DateTime.now().toUtc();
      final response = await _client.get(
        Uri.https(
          'www.googleapis.com',
          '/calendar/v3/calendars/primary/events',
          <String, String>{
            'timeMin': now.toIso8601String(),
            'timeMax': now.add(const Duration(days: 365)).toIso8601String(),
            'singleEvents': 'true',
            'orderBy': 'startTime',
            'maxResults': '100',
          },
        ),
        headers: headers,
      );
      if (response.statusCode == 401) {
        return const CalendarResult.error(
          'Google authorization expired. Reconnect the account and try again.',
        );
      }
      if (response.statusCode != 200) {
        return CalendarResult.error(
          'Google Calendar returned HTTP ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const CalendarResult.error(
          'Google Calendar returned an unexpected response.',
        );
      }
      return CalendarResult.granted(parseEvents(decoded));
    } on GoogleSignInException catch (error) {
      return CalendarResult.error(
        'Google sign-in failed: ${error.description}',
      );
    } on Object catch (error) {
      return CalendarResult.error('Could not reach Google Calendar: $error');
    }
  }

  /// Parses the public Google Calendar v3 event shape without network access.
  static List<ImportedCalendarEvent> parseEvents(
    Map<String, dynamic> response,
  ) {
    final rawItems = response['items'];
    if (rawItems is! List) return const [];

    final events = <ImportedCalendarEvent>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map) continue;
      if (rawItem['status'] == 'cancelled') continue;
      final title = (rawItem['summary'] as String?)?.trim() ?? '';
      final startData = rawItem['start'];
      final endData = rawItem['end'];
      if (title.isEmpty || startData is! Map || endData is! Map) continue;

      final startDate = startData['date'] as String?;
      final startDateTime = startData['dateTime'] as String?;
      final endDate = endData['date'] as String?;
      final endDateTime = endData['dateTime'] as String?;
      final allDay = startDate != null;
      final startValue = startDate ?? startDateTime;
      final endValue = endDate ?? endDateTime;
      if (startValue == null || endValue == null) continue;

      try {
        events.add(
          ImportedCalendarEvent(
            sourceId: rawItem['id'] as String? ?? title,
            title: title,
            start: DateTime.parse(startValue),
            end: DateTime.parse(endValue),
            allDay: allDay,
            location: (rawItem['location'] as String?)?.trim(),
            calendarName: 'Google Calendar',
            provider: CalendarProvider.google,
          ),
        );
      } on FormatException {
        // Ignore malformed provider rows and keep the rest of the calendar.
      }
    }
    events.sort((a, b) => a.start.compareTo(b.start));
    return events;
  }
}

class UnsupportedGoogleCalendarGateway implements GoogleCalendarGateway {
  const UnsupportedGoogleCalendarGateway();

  @override
  GoogleCalendarAccount? get currentAccount => null;

  @override
  bool get isConfigured => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<GoogleCalendarAccount?> restore() async => null;

  @override
  Future<GoogleCalendarAccount> signIn() {
    return Future<GoogleCalendarAccount>.error(
      const GoogleCalendarSetupException(
        'Google Calendar login is available on Android.',
      ),
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<CalendarResult> getUpcomingEvents() async =>
      const CalendarResult.unavailable(
        'Google Calendar login is available on Android.',
      );
}
