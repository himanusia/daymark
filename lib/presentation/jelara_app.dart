import 'package:flutter/material.dart';

import '../data/event_repository.dart';
import '../platform/google_calendar_gateway.dart';
import '../platform/platform_interfaces.dart';
import 'jelara_controller.dart';
import 'jelara_theme.dart';
import 'home_page.dart';

class JelaraApp extends StatelessWidget {
  const JelaraApp({
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
    final controller = JelaraController(
      repository: repository,
      calendar: calendar,
      widget: widget,
      reminders: reminders,
      googleCalendar: googleCalendar,
      clock: clock,
    );
    return MaterialApp(
      title: 'Jelara',
      debugShowCheckedModeBanner: false,
      theme: jelaraLightTheme(),
      darkTheme: jelaraDarkTheme(),
      themeMode: ThemeMode.system,
      home: _JelaraBootstrap(controller: controller),
    );
  }
}

class _JelaraBootstrap extends StatefulWidget {
  const _JelaraBootstrap({required this.controller});

  final JelaraController controller;

  @override
  State<_JelaraBootstrap> createState() => _JelaraBootstrapState();
}

class _JelaraBootstrapState extends State<_JelaraBootstrap> {
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
          return const _JelaraLoading();
        }
        if (snapshot.hasError) {
          return _JelaraLoadError(onRetry: _retry);
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

class _JelaraLoading extends StatelessWidget {
  const _JelaraLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'JELARA',
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

class _JelaraLoadError extends StatelessWidget {
  const _JelaraLoadError({required this.onRetry});

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
                'Jelara could not open your marks.',
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
