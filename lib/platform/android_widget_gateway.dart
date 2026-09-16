import 'package:flutter/services.dart';

import '../domain/countdown.dart';
import '../domain/daymark_event.dart';
import 'platform_interfaces.dart';

class AndroidWidgetGateway implements WidgetGateway {
  AndroidWidgetGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('daymark/widget');

  final MethodChannel _channel;

  @override
  Future<void> update(DaymarkEvent event, CountdownSnapshot snapshot) {
    return _channel.invokeMethod<void>('updateWidget', {
      'title': event.title,
      'countdown': snapshot.displayText,
      'status': snapshot.status.name,
      'eventId': event.id,
    });
  }

  @override
  Future<void> clear() {
    return _channel.invokeMethod<void>('clearWidget');
  }
}
