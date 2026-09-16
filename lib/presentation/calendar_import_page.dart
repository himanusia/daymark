import 'dart:async';

import 'package:flutter/material.dart';

import '../platform/platform_interfaces.dart';

class CalendarImportPage extends StatefulWidget {
  const CalendarImportPage({
    super.key,
    required this.calendar,
    this.googleCalendar,
  });

  final CalendarGateway calendar;
  final GoogleCalendarGateway? googleCalendar;

  @override
  State<CalendarImportPage> createState() => _CalendarImportPageState();
}

class _CalendarImportPageState extends State<CalendarImportPage> {
  late Future<CalendarResult> _result;
  CalendarProvider _provider = CalendarProvider.device;
  GoogleCalendarAccount? _googleAccount;
  bool _googleWorking = false;

  @override
  void initState() {
    super.initState();
    _googleAccount = widget.googleCalendar?.currentAccount;
    _result = widget.calendar.getUpcomingEvents();
    final google = widget.googleCalendar;
    if (google != null && _googleAccount == null) {
      unawaited(_restoreGoogle(google));
    }
  }

  Future<void> _restoreGoogle(GoogleCalendarGateway google) async {
    try {
      final account = await google.restore();
      if (mounted && account != null) {
        setState(() => _googleAccount = account);
      }
    } on Object {
      // A missing or expired Google session is represented by the connect card.
    }
  }

  @override
  Widget build(BuildContext context) {
    final google = widget.googleCalendar;
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar sync')),
      body: SafeArea(
        child: Column(
          children: [
            if (google != null) ...[
              _GoogleConnectionPanel(
                gateway: google,
                account: _googleAccount,
                working: _googleWorking,
                onConnect: _connectGoogle,
                onDisconnect: _disconnectGoogle,
                onSync: _reload,
              ),
              if (_googleAccount != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SegmentedButton<CalendarProvider>(
                    segments: const [
                      ButtonSegment<CalendarProvider>(
                        value: CalendarProvider.device,
                        label: Text('Device'),
                        icon: Icon(Icons.phone_android_outlined),
                      ),
                      ButtonSegment<CalendarProvider>(
                        value: CalendarProvider.google,
                        label: Text('Google'),
                        icon: Icon(Icons.cloud_outlined),
                      ),
                    ],
                    selected: {_provider},
                    onSelectionChanged: (selection) {
                      _changeProvider(selection.first);
                    },
                  ),
                ),
            ],
            Expanded(
              child: FutureBuilder<CalendarResult>(
                future: _result,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final result = snapshot.data;
                  if (result == null) {
                    return _StatusView(
                      icon: Icons.error_outline,
                      title: 'Calendar unavailable',
                      message:
                          'H- could not read a response from the calendar.',
                      actionLabel: 'Try again',
                      onAction: _reload,
                    );
                  }
                  switch (result.status) {
                    case CalendarResultStatus.granted:
                      return _EventList(
                        events: result.events,
                        provider: _provider,
                      );
                    case CalendarResultStatus.empty:
                      return _StatusView(
                        icon: Icons.event_available_outlined,
                        title: 'No upcoming events',
                        message: _provider == CalendarProvider.google
                            ? 'Google Calendar has no events in the next year.'
                            : 'This device calendar has no events in the next year.',
                        actionLabel: 'Refresh',
                        onAction: _reload,
                      );
                    case CalendarResultStatus.denied:
                      return _StatusView(
                        icon: Icons.lock_outline,
                        title: _provider == CalendarProvider.google
                            ? 'Google Calendar is not connected'
                            : 'Calendar access is off',
                        message:
                            result.message ??
                            (_provider == CalendarProvider.google
                                ? 'Connect a Google account to read its calendar.'
                                : 'Allow read-only access to choose an event from this device.'),
                        actionLabel: _provider == CalendarProvider.google
                            ? 'Connect Google'
                            : 'Allow calendar access',
                        onAction: _provider == CalendarProvider.google
                            ? _connectGoogle
                            : _reload,
                      );
                    case CalendarResultStatus.unavailable:
                      return _StatusView(
                        icon: Icons.settings_outlined,
                        title: _provider == CalendarProvider.google
                            ? 'Google Calendar setup needed'
                            : 'Android calendar only',
                        message:
                            result.message ??
                            (_provider == CalendarProvider.google
                                ? 'Add the OAuth client ID to this build first.'
                                : 'Calendar import is available on the Android device.'),
                        actionLabel: _provider == CalendarProvider.google
                            ? 'Read setup note'
                            : 'Try again',
                        onAction: _provider == CalendarProvider.google
                            ? _showGoogleSetupNote
                            : _reload,
                      );
                    case CalendarResultStatus.error:
                      return _StatusView(
                        icon: Icons.sync_problem_outlined,
                        title: 'Could not sync calendar',
                        message: result.message ?? 'Try again in a moment.',
                        actionLabel: 'Try again',
                        onAction: _reload,
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectGoogle() async {
    final google = widget.googleCalendar;
    if (google == null || _googleWorking) return;
    setState(() => _googleWorking = true);
    try {
      final account = await google.signIn();
      if (!mounted) return;
      setState(() {
        _googleAccount = account;
        _provider = CalendarProvider.google;
        _result = google.getUpcomingEvents();
      });
    } on Object catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _googleWorking = false);
    }
  }

  Future<void> _disconnectGoogle() async {
    final google = widget.googleCalendar;
    if (google == null || _googleWorking) return;
    setState(() => _googleWorking = true);
    try {
      await google.signOut();
      if (!mounted) return;
      setState(() {
        _googleAccount = null;
        _provider = CalendarProvider.device;
        _result = widget.calendar.getUpcomingEvents();
      });
    } on Object catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _googleWorking = false);
    }
  }

  void _changeProvider(CalendarProvider provider) {
    setState(() {
      _provider = provider;
      _result = _futureFor(provider);
    });
  }

  Future<CalendarResult> _futureFor(CalendarProvider provider) {
    if (provider == CalendarProvider.google && widget.googleCalendar != null) {
      return widget.googleCalendar!.getUpcomingEvents();
    }
    return widget.calendar.getUpcomingEvents();
  }

  void _reload() {
    setState(() => _result = _futureFor(_provider));
  }

  void _showGoogleSetupNote() {
    _showMessage(
      'Build with --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client ID>.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GoogleConnectionPanel extends StatelessWidget {
  const _GoogleConnectionPanel({
    required this.gateway,
    required this.account,
    required this.working,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSync,
  });

  final GoogleCalendarGateway gateway;
  final GoogleCalendarAccount? account;
  final bool working;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final connected = account != null;
    return Card(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primary.withValues(alpha: 0.14),
                  child: Icon(
                    Icons.account_circle_outlined,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connected
                            ? 'Google Calendar connected'
                            : 'Google Calendar',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        connected ? account!.email : 'Read-only sync. Sign in to choose events directly.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.66),
                        ),
                      ),
                    ],
                  ),
                ),
                if (connected)
                  Icon(Icons.check_circle, color: colors.primary, size: 20),
              ],
            ),
            if (!connected && !gateway.isConfigured) ...[
              const SizedBox(height: 10),
              Text(
                'This build still needs a Google web OAuth client ID.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.error),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: connected
                    ? [
                        TextButton(
                          onPressed: working ? null : onDisconnect,
                          child: const Text('Disconnect'),
                        ),
                        FilledButton.icon(
                          onPressed: working ? null : onSync,
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync now'),
                        ),
                      ]
                    : [
                        FilledButton.icon(
                          onPressed: gateway.isConfigured && !working
                              ? onConnect
                              : null,
                          icon: const Icon(Icons.login),
                          label: Text(
                            gateway.isConfigured
                                ? 'Connect Google'
                                : 'Needs setup',
                          ),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events, required this.provider});

  final List<ImportedCalendarEvent> events;
  final CalendarProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: events.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 18 : 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            provider == CalendarProvider.google
                ? 'UPCOMING FROM GOOGLE CALENDAR'
                : 'UPCOMING ON YOUR DEVICE',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          );
        }
        final event = events[index - 1];
        return _CalendarEventTile(event: event);
      },
    );
  }
}

class _CalendarEventTile extends StatelessWidget {
  const _CalendarEventTile({required this.event});

  final ImportedCalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final start = event.start.toLocal();
    final date = _formatDate(start);
    final time = event.allDay ? 'All day' : _formatTime(start);
    final details = event.location == null
        ? '$date · $time'
        : '$date · $time\n${event.location}';
    return Semantics(
      button: true,
      label: 'Import ${event.title}, $details',
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(event),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    event.allDay
                        ? Icons.wb_sunny_outlined
                        : Icons.event_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.64),
                        ),
                      ),
                      if (event.calendarName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.calendarName!,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.add_circle_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[value.weekday - 1]}, ${months[value.month - 1]} ${value.day}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    return '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 54,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.66),
                ),
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
