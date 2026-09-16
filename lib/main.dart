import 'package:flutter/material.dart';

import 'data/event_repository.dart';
import 'platform/platform_services.dart';
import 'presentation/jelara_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = PlatformServices.current();
  await services.googleCalendar.initialize();
  runApp(
    JelaraApp(
      repository: SharedPreferencesEventRepository(),
      calendar: services.calendar,
      widget: services.widget,
      reminders: services.reminders,
      googleCalendar: services.googleCalendar,
    ),
  );
}
