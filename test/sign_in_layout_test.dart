import 'package:car_alerts/l10n/app_localizations.dart';
import 'package:car_alerts/screens/sign_in_screen.dart';
import 'package:car_alerts/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'local_mode_screens_test.dart' show CancelledAuthentication;

void main() {
  testWidgets('banner follows content fit and restores full layout on resize',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SignInScreen(authentication: CancelledAuthentication()),
    ));
    await tester.pumpAndSettle();
    final banner = find.byKey(const ValueKey('welcome-banner'));
    final form = find.byKey(const ValueKey('auth-content'));
    final fullHeight = tester.getSize(banner).height;
    final requiredHeight =
        fullHeight + tester.getSize(form).height + 8 + 20 + 24;
    tester.view.physicalSize = Size(430, requiredHeight + 2);
    await tester.pumpAndSettle();
    expect(tester.getSize(banner).height, fullHeight);
    tester.view.physicalSize = Size(430, requiredHeight - 2);
    await tester.pumpAndSettle();
    expect(tester.getSize(banner).height, lessThan(fullHeight));
    tester.view.physicalSize = Size(430, requiredHeight + 2);
    await tester.pumpAndSettle();
    expect(tester.getSize(banner).height, fullHeight);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  for (final size in [
    const Size(375, 667),
    const Size(375, 812),
    const Size(430, 932)
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final returnToLocal in [false, true]) {
        testWidgets(
            'sign in remains reachable at $size, text scale $scale, back=$returnToLocal',
            (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: SignInScreen(
                returnToLocal: returnToLocal,
                authentication: CancelledAuthentication()),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final banner = find.byKey(const ValueKey('welcome-banner'));
          expect(banner, findsOneWidget);
          final back = find.byType(BackButtonIcon);
          expect(back, returnToLocal ? findsOneWidget : findsNothing);
          if (returnToLocal) {
            expect(tester.getBottomLeft(back).dy,
                lessThan(tester.getTopLeft(banner).dy));
            expect(find.widgetWithText(TextButton, 'Go back'), findsNothing);
            expect(find.text('Continue without an account'), findsNothing);
          }
          final bannerPosition = tester.getTopLeft(banner);
          for (final label in [
            'Sign in with Apple',
            if (!returnToLocal) 'Continue without an account'
          ]) {
            final action = find.widgetWithText(OutlinedButton, label);
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            expect(action.hitTestable(), findsOneWidget);
            expect(tester.getTopLeft(banner), bannerPosition);
          }
          await tester.ensureVisible(find.byType(TextFormField).first);
          await tester.tap(find.byType(TextFormField).first);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          expect(banner, findsNothing);
          await tester.enterText(
              find.byType(TextFormField).first, 'driver@example.com');
          await tester.pumpAndSettle();
          final submit = find.widgetWithText(FilledButton, 'Sign in');
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          expect(submit.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          expect(banner, findsOneWidget);
          expect(find.text('driver@example.com'), findsOneWidget);
        }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
      }
    }
  }
}
