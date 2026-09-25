import 'package:flutter/widgets.dart';

/// Use the phone's primary language, regardless of region or script variant.
Locale deviceLanguage([Locale? phoneLocale]) {
  final locale =
      phoneLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
  return Locale(locale.languageCode == 'ro' ? 'ro' : 'en');
}
