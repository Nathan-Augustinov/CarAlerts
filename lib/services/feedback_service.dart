import 'package:flutter/services.dart';

enum FeedbackType {
  improvement('Suggest an improvement'),
  problem('Report a problem');

  const FeedbackType(this.label);
  final String label;
  String get subject => 'CarAlerts — $label';
}

class FeedbackService {
  static const recipient = 'nathanaugustinov@gmail.com';
  static const _channel = MethodChannel('car_alerts/feedback');

  Future<void> compose(FeedbackType type, String message) async {
    final details =
        await _channel.invokeMapMethod<String, String>('deviceDetails');
    if (details == null) {
      throw PlatformException(code: 'details_unavailable');
    }
    final body = '${message.trim()}\n\n\n'
        'Device details\n'
        'Phone model: ${details['model'] ?? 'Unavailable'}\n'
        'OS version: ${details['os'] ?? 'Unavailable'}\n'
        'App version: ${details['version'] ?? 'Unavailable'}';
    final query = {'subject': type.subject, 'body': body}
        .entries
        .map((entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    await _channel.invokeMethod<void>('compose', {
      'uri': 'mailto:$recipient?$query',
    });
  }
}
