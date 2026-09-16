import 'package:flutter_test/flutter_test.dart';

import 'package:jelara/data/event_repository.dart';
import 'package:jelara/domain/jelara_event.dart';
import 'package:jelara/platform/platform_interfaces.dart';
import 'package:jelara/presentation/jelara_app.dart';

void main() {
  testWidgets('renders a focal mark with its semantic countdown state', (
    tester,
  ) async {
    final event = JelaraEvent(
      id: 'launch',
      title: 'Product launch',
      start: DateTime(2026, 9, 20),
      allDay: true,
    );

    await tester.pumpWidget(
      JelaraApp(
        repository: MemoryEventRepository(
          events: [event],
          selectedId: event.id,
        ),
        calendar: UnsupportedCalendarGateway(),
        widget: UnsupportedWidgetGateway(),
        reminders: UnsupportedReminderGateway(),
        clock: () => DateTime(2026, 9, 16, 21),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('JELARA'), findsOneWidget);
    expect(find.text('Make time visible.'), findsOneWidget);
    expect(find.text('Product launch'), findsNWidgets(2));
    expect(find.text('D-4'), findsNWidgets(2));
    expect(find.text('UPCOMING'), findsWidgets);
  });
}
