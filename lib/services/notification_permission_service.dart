import 'package:flutter/services.dart';

enum NotificationPermission { enabled, notRequested, disabled }

/// Always reads the OS; no permission status is persisted in Firestore.
class NotificationPermissionService {
  static const _channel = MethodChannel('car_alerts/notification_permissions');

  Future<NotificationPermission> status() async =>
      _decode(await _channel.invokeMethod<String>('status'));

  Future<NotificationPermission> request() async =>
      _decode(await _channel.invokeMethod<String>('request'));

  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  Future<void> requestIfNotAsked() async {
    if (await status() == NotificationPermission.notRequested) {
      await request();
    }
  }

  NotificationPermission _decode(String? value) => switch (value) {
        'enabled' => NotificationPermission.enabled,
        'notRequested' => NotificationPermission.notRequested,
        'disabled' => NotificationPermission.disabled,
        _ => throw PlatformException(code: 'unknown_permission'),
      };
}
