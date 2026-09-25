import 'dart:convert';
import 'dart:io';
import 'package:car_alerts/l10n/app_localizations.dart';
import 'package:car_alerts/l10n/localized_content.dart';
import 'package:car_alerts/services/language_controller.dart';
import 'package:car_alerts/services/user_settings_service.dart';
import 'package:car_alerts/services/reminder_coordinator.dart';
import 'package:car_alerts/theme/app_theme.dart';
import 'package:car_alerts/widgets/language_setting.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'reminder_account_changes_test.dart' show MemoryReminders;

class LocalizedBackend extends MemoryReminders {
  String code = 'en';
  @override
  String get language => code;
}

void main() {
  test('catalogs have matching keys and Romanian plural forms', () {
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final ro =
        jsonDecode(File('lib/l10n/app_ro.arb').readAsStringSync()) as Map;
    expect(en.keys.where((k) => !k.startsWith('@')).toSet(),
        ro.keys.where((k) => !k.startsWith('@')).toSet());
    final l = lookupAppLocalizations(const Locale('ro'));
    expect(l.carsNeedAttention(1), 'O mașină necesită atenție');
    expect(l.carsNeedAttention(2), '2 mașini necesită atenție');
    expect(l.carsNeedAttention(20), '20 de mașini necesită atenție');
  });

  test('default backfill preserves preferences and saved language', () async {
    final db = FakeFirebaseFirestore();
    final ref = db.doc('users/a/settings/user_settings');
    await ref.set({'darkMode': true});
    final service = UserSettingsService(firestore: db);
    await service.initializeForUser('a');
    expect((await ref.get()).data(), {'darkMode': true, 'language': 'en'});
    await ref.update({'language': 'ro'});
    await service.initializeForUser('a');
    expect((await ref.get()).data()?['language'], 'ro');
  });

  test('language persists, resets on sign-out and follows account changes',
      () async {
    final db = FakeFirebaseFirestore();
    final controller = LanguageController(firestore: db);
    addTearDown(controller.dispose);
    expect(controller.locale.languageCode, 'en');
    controller.bindUser('a');
    await Future<void>.delayed(Duration.zero);
    await controller.select('ro');
    expect(controller.locale.languageCode, 'ro');
    expect(
        (await db.doc('users/a/settings/user_settings').get())
            .data()?['language'],
        'ro');
    controller.bindUser(null);
    expect(controller.locale.languageCode, 'en');
    controller.bindUser('b');
    await Future<void>.delayed(Duration.zero);
    expect(controller.locale.languageCode, 'en');
    controller.bindUser('a');
    await Future<void>.delayed(Duration.zero);
    expect(controller.locale.languageCode, 'ro');
    await db.doc('users/a/settings/user_settings').update({'language': 'xx'});
    await Future<void>.delayed(Duration.zero);
    expect(controller.locale.languageCode, 'en');
    await expectLater(controller.select('fr'), throwsArgumentError);
  });

  testWidgets('selector changes locale live and formats Romanian dates',
      (tester) async {
    final controller = LanguageController(firestore: FakeFirebaseFirestore());
    addTearDown(controller.dispose);
    controller.bindUser('a');
    await tester.pumpWidget(ListenableBuilder(
        listenable: controller,
        builder: (_, __) => MaterialApp(
              theme: AppTheme.light,
              locale: controller.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: LanguageSetting(controller: controller)),
            )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsWidgets);
    await tester.tap(find.text('Romanian'));
    await tester.pumpAndSettle();
    expect(find.text('Limbă'), findsOneWidget);
    expect(find.text('Română'), findsOneWidget);
    final context = tester.element(find.byType(LanguageSetting));
    expect(localizedDate(context, '2030-01-02'), contains('ian.'));
    await tester.tap(find.text('Limbă'));
    await tester.pumpAndSettle();
    expect(find.text('Engleză'), findsOneWidget);
    await tester.tap(find.text('Engleză'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('language change updates pending reminders without changing IDs',
      () async {
    tzdata.initializeTimeZones();
    final backend = LocalizedBackend();
    backend.savedCars = {
      'CAR': {'insurance_date': '2030-08-01'}
    };
    final coordinator =
        ReminderCoordinator(backend, now: () => DateTime.utc(2030, 6));
    await coordinator.refresh();
    final ids = Map.of(backend.ids);
    backend.code = 'ro';
    await coordinator.refresh();
    expect(backend.ids, ids);
    expect(
        backend.requests.values
            .every((p) => jsonDecode(p!)['language'] == 'ro'),
        isTrue);
    expect(
        backend.requests.values
            .every((p) => jsonDecode(p!)['title'] == 'CAR · Asigurare auto'),
        isTrue);
    final reminder = Reminder(
        'a', 'CAR', 'insurance_date', 7, tz.TZDateTime(tz.UTC, 2030, 7, 25),
        language: 'ro');
    expect(reminder.body, 'Expiră în 7 zile.');
  });
}
