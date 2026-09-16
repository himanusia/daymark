import 'package:flutter/material.dart';

import '../data/event_repository.dart';
import '../platform/google_calendar_gateway.dart';
import '../platform/platform_interfaces.dart';
import 'daymark_controller.dart';
import 'daymark_theme.dart';
import 'home_page.dart';

class DaymarkApp extends StatelessWidget {
  const DaymarkApp({
    super.key,
    required this.repository,
    required this.calendar,
    required this.widget,
    required this.reminders,
    this.googleCalendar = const UnsupportedGoogleCalendarGateway(),
    this.clock,
  });

  final EventRepository repository;
  final CalendarGateway calendar;
  final WidgetGateway widget;
  final ReminderGateway reminders;
  final GoogleCalendarGateway googleCalendar;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final controller = DaymarkController(
      repository: repository,
      calendar: calendar,
      widget: widget,
      reminders: reminders,
      googleCalendar: googleCalendar,
      clock: clock,
    );
    return MaterialApp(
      title: 'H- Countdown',
      debugShowCheckedModeBanner: false,
      theme: daymarkLightTheme(),
      darkTheme: daymarkDarkTheme(),
      themeMode: ThemeMode.system,
      home: _DaymarkBootstrap(controller: controller),
    );
  }
}

class _DaymarkBootstrap extends StatefulWidget {
  const _DaymarkBootstrap({required this.controller});

  final DaymarkController controller;

  @override
  State<_DaymarkBootstrap> createState() => _DaymarkBootstrapState();
}

class _DaymarkBootstrapState extends State<_DaymarkBootstrap> {
  late Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = widget.controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DaymarkLoading();
        }
        if (snapshot.hasError) {
          return _DaymarkLoadError(onRetry: _retry);
        }
        return HomePage(controller: widget.controller);
      },
    );
  }

  void _retry() {
    setState(() {
      _ready = widget.controller.initialize();
    });
  }
}

class _DaymarkLoading extends StatelessWidget {
  const _DaymarkLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'H- COUNTDOWN',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaymarkLoadError extends StatelessWidget {
  const _DaymarkLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'H- Countdown could not open your marks.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
