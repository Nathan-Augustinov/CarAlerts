import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A device preference, independent of the signed-in account.
class AppearanceController extends ChangeNotifier {
  AppearanceController();

  static final instance = AppearanceController();
  static const _channel = MethodChannel('car_alerts/appearance');
  ThemeMode _mode = ThemeMode.system;
  bool _saving = false;

  ThemeMode get mode => _mode;
  bool get saving => _saving;

  Future<void> load() async {
    try {
      final value = await _channel.invokeMethod<String>('load');
      _mode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } on PlatformException {
      _mode = ThemeMode.system;
    } on MissingPluginException {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> select(ThemeMode value) async {
    if (_saving || value == _mode) return;
    final previous = _mode;
    _mode = value;
    _saving = true;
    notifyListeners();
    try {
      await _channel.invokeMethod<void>('save', value.name);
    } catch (_) {
      _mode = previous;
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}

extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };
}
