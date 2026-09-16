import 'package:flutter_test/flutter_test.dart';

import 'package:daymark/data/event_repository.dart';
import 'package:daymark/domain/daymark_event.dart';
import 'package:daymark/platform/platform_interfaces.dart';
import 'package:daymark/presentation/daymark_app.dart';

void main() {
  testWidgets('renders a focal mark with its semantic countdown state', (
    tester,
  ) async {
    final event = DaymarkEvent(
      id: 'launch',
      title: 'Product launch',
      start: DateTime(2026, 9, 20),
      allDay: true,
    );

    await tester.pumpWidget(
      DaymarkApp(
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

    expect(find.text('H- COUNTDOWN'), findsOneWidget);
    expect(find.text('Make time visible.'), findsOneWidget);
    expect(find.text('Product launch'), findsNWidgets(2));
    expect(find.text('D-4'), findsNWidgets(2));
    expect(find.text('UPCOMING'), findsWidgets);
  });
}
