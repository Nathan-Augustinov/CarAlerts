import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/car.dart';
import 'app_localizations.dart';

String documentLabel(AppLocalizations l, String key) => switch (key) {
      'insurance_date' => l.carInsurance,
      'inspection_date' => l.carInspection,
      'romanian_vignette_date' => l.romanianVignette,
      'hungarian_vignette_date' => l.hungarianVignette,
      'austrian_vignette_date' => l.austrianVignette,
      _ => l.document,
    };

String carItemLabel(BuildContext context, Car car, String key) =>
    key.startsWith('custom:')
        ? car.itemLabel(key)
        : documentLabel(AppLocalizations.of(context)!, key);

String localizedDate(BuildContext context, String value) {
  final date = DateTime.tryParse(value.split('T').first);
  return date == null
      ? AppLocalizations.of(context)!.invalidDate
      : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
          .format(date);
}
