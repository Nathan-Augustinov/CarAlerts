import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';

enum FeedbackType {
  improvement('Suggest an improvement'),
  problem('Report a problem');

  const FeedbackType(this.label);
  final String label;
  String localizedLabel(AppLocalizations l) => this == FeedbackType.improvement
      ? l.suggestAnImprovement
      : l.reportAProblem;
  String localizedSubject(AppLocalizations l) =>
      'CarAlerts — ${localizedLabel(l)}';
  String get subject => 'CarAlerts — $label';
}

class FeedbackService {
  static const recipient = 'nathanaugustinov@gmail.com';
  static const _channel = MethodChannel('car_alerts/feedback');

  Future<void> compose(FeedbackType type, String message,
      {AppLocalizations? localizations}) async {
    final details =
        await _channel.invokeMapMethod<String, String>('deviceDetails');
    if (details == null) {
      throw PlatformException(code: 'details_unavailable');
    }
    final l = localizations ?? lookupAppLocalizations(const Locale('en'));
    final body = '${message.trim()}\n\n\n'
        '${l.deviceDetails}\n'
        '${l.phoneModel}: ${details['model'] ?? l.unavailable}\n'
        '${l.osVersion}: ${details['os'] ?? l.unavailable}\n'
        '${l.appVersion}: ${details['version'] ?? l.unavailable}';
    final query = {
      'subject': localizations == null
          ? type.subject
          : type.localizedSubject(localizations),
      'body': body
    }
        .entries
        .map((entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    await _channel.invokeMethod<void>('compose', {
      'uri': 'mailto:$recipient?$query',
    });
  }
}
