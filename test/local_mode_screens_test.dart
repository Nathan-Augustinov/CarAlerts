import 'dart:async';
import 'package:car_alerts/l10n/app_localizations.dart';
import 'package:car_alerts/screens/local_transfer_screen.dart';
import 'package:car_alerts/screens/sign_in_screen.dart';
import 'package:car_alerts/services/authentication_service.dart';
import 'package:car_alerts/services/local_car_store.dart';
import 'package:car_alerts/services/local_car_transfer.dart';
import 'package:car_alerts/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'local_mode_test.dart' show TestFirestore;

class CancelledAuthentication implements AuthenticationGateway {
  bool fail = false;
  @override
  Future<User?> signInWithGoogle() async {
    if (fail) throw FirebaseAuthException(code: 'network-request-failed');
    return null;
  }

  @override
  Future<User?> signInWithApple() => signInWithGoogle();
  @override
  Future<User?> signInWithEmail(String email, String password) =>
      signInWithGoogle();
  @override
  Future<User?> createAccount(String email, String password) =>
      signInWithGoogle();
  @override
  Future<void> resetPassword(String email) async {}
}

Widget app(Widget home, {String language = 'en'}) => MaterialApp(
      locale: Locale(language),
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
void main() {
  late LocalCarStore local;
  late TestFirestore db;
  late String disk;
  const deviceDates = {'insurance_date': '2090-03-01'};
  setUp(() async {
    disk = '{}';
    local = LocalCarStore(read: () async => disk, write: (s) async => disk = s);
    await local.load();
    await local.save(registration: 'CAR', dates: deviceDates);
    db = TestFirestore();
  });
  Future<void> openTransfer(WidgetTester tester,
      {String language = 'en'}) async {
    await tester.pumpWidget(app(
        LocalTransferScreen(
          account: 'a',
          transfer: LocalCarTransfer(
              local: local, firestore: db, currentUser: () => 'a'),
          refreshReminders: () async {},
        ),
        language: language));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'deletion requires its own confirmation, back preserves both copies',
      (tester) async {
    await db.doc('cars/a/user_cars/CAR').set(deviceDates);
    final cloudBefore = db.dump();
    await openTransfer(tester);
    await tester.tap(find.text('Delete from this device'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this car from your device?'), findsOneWidget);
    expect(local.registration, 'CAR');
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(local.registration, 'CAR');
    await tester.tap(find.text('Delete from this device'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Delete and continue'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(local.registration, isNull);
    expect(db.dump(), cloudBefore);
  });
  testWidgets('interrupting the decision never deletes and reopens on recovery',
      (tester) async {
    await openTransfer(tester);
    await tester.tap(find.text('Delete from this device'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await local.load();
    expect(local.registration, 'CAR');
    await openTransfer(tester);
    expect(find.text('Move your car to your account?'), findsOneWidget);
  });
  testWidgets('identical car moves without conflict or success messages',
      (tester) async {
    await db.doc('cars/a/user_cars/CAR').set(deviceDates);
    await openTransfer(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('Move to my account'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(local.registration, isNull);
    expect(find.text('This car already exists in your account'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect((await db.doc('cars/a/user_cars/CAR').get()).data(), deviceDates);
  });
  testWidgets(
      'duplicate shows both dates and retry preserves keep-account intent',
      (tester) async {
    await db.doc('cars/a/user_cars/CAR').set({'insurance_date': '2095-04-02'});
    await openTransfer(tester);
    await tester.tap(find.text('Move to my account'));
    await tester.pumpAndSettle();
    expect(
        find.text('This car already exists in your account'), findsOneWidget);
    expect(find.textContaining('2090'), findsOneWidget);
    expect(find.textContaining('2095'), findsOneWidget);
    db.fail = true;
    await tester.tap(find.text('Keep my account’s data'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(local.registration, 'CAR');
    db.fail = false;
    await tester.runAsync(() async {
      await tester.tap(find.text('Try again'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect((await db.doc('cars/a/user_cars/CAR').get()).data(),
        {'insurance_date': '2095-04-02'});
    expect(local.registration, isNull);
  });
  testWidgets('saving disables actions and Romanian transfer copy is localized',
      (tester) async {
    db.gate = Completer<void>();
    await openTransfer(tester, language: 'ro');
    expect(find.text('Muți mașina în cont?'), findsOneWidget);
    await tester.tap(find.text('Mută în contul meu'));
    await tester.pump();
    expect(find.text('Se salvează mașina în cont…'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);
    await tester.runAsync(() async {
      db.gate!.complete();
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(local.registration, isNull);
  });
  for (final fail in [false, true]) {
    testWidgets(
        'cancelled/failed authentication (failure=$fail) returns to local data',
        (tester) async {
      final auth = CancelledAuthentication()..fail = fail;
      final before = disk;
      await tester.pumpWidget(app(Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => SignInScreen(
                            returnToLocal: true, authentication: auth))),
                child: const Text('Local dashboard'),
              )))));
      await tester.tap(find.text('Local dashboard'));
      await tester.pumpAndSettle();
      final google = find.widgetWithText(OutlinedButton, 'Sign in with Google');
      await tester.ensureVisible(google);
      await tester.pumpAndSettle();
      await tester.tap(google);
      await tester.pumpAndSettle();
      expect(find.text('Local dashboard'), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
      expect(disk, before);
      expect(local.registration, 'CAR');
    });
  }
}
