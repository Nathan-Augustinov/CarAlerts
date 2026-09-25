import 'package:flutter/widgets.dart';
import 'crash_reporting_service.dart';

class CrashNavigationObserver extends NavigatorObserver {
  static String homeScreen = 'sign_in';
  void _show(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    final name = route.settings.name;
    CrashReportingService.instance
        .screen(name == null || name == '/' ? homeScreen : name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _show(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _show(previousRoute);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _show(newRoute);
}
