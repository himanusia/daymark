import 'package:flutter_test/flutter_test.dart';

import 'package:its_the_day/data/event_repository.dart';
import 'package:its_the_day/domain/itstheday_event.dart';
import 'package:its_the_day/platform/platform_interfaces.dart';
import 'package:its_the_day/presentation/itstheday_app.dart';

void main() {
  testWidgets('renders a focal mark with its semantic countdown state', (
    tester,
  ) async {
    final event = ItsTheDayEvent(
      id: 'launch',
      title: 'Product launch',
      start: DateTime(2026, 9, 20),
      allDay: true,
    );

    await tester.pumpWidget(
      ItsTheDayApp(
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

    expect(find.text("IT'S THE DAY!"), findsOneWidget);
    expect(find.text('Make time visible.'), findsOneWidget);
    expect(find.text('Product launch'), findsNWidgets(2));
    expect(find.text('D-4'), findsNWidgets(2));
    expect(find.text('UPCOMING'), findsWidgets);
  });
}
