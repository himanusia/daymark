import 'package:flutter/services.dart';

import '../domain/countdown.dart';
import '../domain/jelara_event.dart';
import 'platform_interfaces.dart';

class AndroidWidgetGateway implements WidgetGateway {
  AndroidWidgetGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('jelara/widget');

  final MethodChannel _channel;

  @override
  Future<void> update(JelaraEvent event, CountdownSnapshot snapshot) {
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
