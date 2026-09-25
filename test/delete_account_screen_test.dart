import 'dart:async';
import 'package:car_alerts/screens/delete_account_screen.dart';
import 'package:car_alerts/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openScreen(
    WidgetTester tester, Future<void> Function(String?) onDelete,
    {bool password = true, bool dark = false}) async {
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: Builder(
        builder: (context) => Scaffold(
                body: TextButton(
              child: const Text('Open deletion'),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => DeleteAccountScreen(
                    email: 'test@example.com',
                    requiresPassword: password,
                    onDelete: onDelete),
              )),
            ))),
  ));
  await tester.tap(find.text('Open deletion'));
  await tester.pumpAndSettle();
}

Future<void> requestDeletion(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Delete account');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('password is required before confirmation', (tester) async {
    await openScreen(tester, (_) async => fail('Must not delete'));
    await requestDeletion(tester);
    expect(find.text('Enter your current password.'), findsOneWidget);
    expect(find.text('Delete permanently'), findsNothing);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'confirmation can be cancelled in ${dark ? 'dark' : 'light'} theme',
        (tester) async {
      await openScreen(tester, (_) async => fail('Must not delete'),
          dark: dark);
      await tester.enterText(find.byType(TextFormField), 'password');
      await requestDeletion(tester);
      expect(find.text('Delete your account?'), findsOneWidget);
      await tester.tap(find.text('Keep account'));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('wrong password gives a recoverable error', (tester) async {
    await openScreen(tester,
        (_) async => throw FirebaseAuthException(code: 'wrong-password'));
    await tester.enterText(find.byType(TextFormField), 'incorrect');
    await requestDeletion(tester);
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Your password was not accepted. Please check it and try again.'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });

  testWidgets(
      'Google deletion needs confirmation, blocks repeats, then returns',
      (tester) async {
    final gate = Completer<void>();
    var calls = 0;
    await openScreen(tester, (password) {
      expect(password, isNull);
      calls++;
      return gate.future;
    }, password: false);
    expect(find.byType(TextFormField), findsNothing);
    await requestDeletion(tester);
    expect(calls, 0);
    await tester.tap(find.text('Verify with Google & delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(
        tester.widget<PopScope>(find.byType(PopScope).first).canPop, isFalse);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Open deletion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('different Google account leaves deletion available to retry',
      (tester) async {
    await openScreen(
        tester, (_) async => throw FirebaseAuthException(code: 'user-mismatch'),
        password: false);
    expect(find.textContaining('Select test@example.com.'), findsOneWidget);
    await requestDeletion(tester);
    expect(find.textContaining('Select test@example.com.'), findsOneWidget);
    await tester.tap(find.text('Verify with Google & delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('That is a different account.'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(FilledButton), 100);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });

  testWidgets(
      'auth navigation during deletion does not pop the destination route',
      (tester) async {
    final gate = Completer<void>();
    await openScreen(tester, (_) => gate.future);
    await tester.enterText(find.byType(TextFormField), 'password');
    await requestDeletion(tester);
    await tester.tap(find.text('Delete permanently'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Firebase's auth listener removes the route before delete() completes.
    Navigator.of(tester.element(find.byType(DeleteAccountScreen)))
        .popUntil((route) => route.isFirst);
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Open deletion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
