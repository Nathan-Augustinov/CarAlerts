import 'services/crash_navigation_observer.dart';
import 'services/crash_reporting_service.dart';
import 'l10n/app_localizations.dart';
import 'services/language_controller.dart';
import 'package:flutter/services.dart';
import 'services/appearance_controller.dart';
import 'theme/app_theme.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/notifications_service.dart';
import 'models/car.dart';
import 'screens/add_or_edit_car_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/sign_in_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';

GlobalKey<MainScreenState> mainScreenKey = GlobalKey();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final reporting = CrashReportingService.instance;
  await reporting.initialize();
  await reporting.setUser(FirebaseAuth.instance.currentUser?.uid);
  reporting.installHandlers();
  await AppearanceController.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _crashNavigation = CrashNavigationObserver();
  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<User?>? _auth;
  late final _authState = FirebaseAuth.instance.authStateChanges();
  String? _renderedUser;
  final _notifications = NotificationsService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications.onTap = _openReminder;
    LanguageController.instance.addListener(_languageChanged);
    _auth = _authState.listen((user) {
      if (user == null) {
        CrashNavigationObserver.homeScreen = 'sign_in';
        unawaited(CrashReportingService.instance.screen('sign_in'));
      }
      unawaited(CrashReportingService.instance.setUser(user?.uid));
      unawaited(CrashReportingService.instance
          .breadcrumb(user == null ? 'auth: signed_out' : 'auth: signed_in'));
      LanguageController.instance.bindUser(user?.uid);
      _navigator.currentState?.popUntil((route) => route.isFirst);
      _refresh();
    });
  }

  void _languageChanged() {
    if (!LanguageController.instance.saving) _refresh();
  }

  Future<void> _refresh() async {
    await _notifications.refresh();
    if (!mounted) return;
    final payload = _notifications.launchPayload;
    if (payload != null) {
      _notifications.launchPayload = null;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openReminder(payload));
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  Future<void> _openReminder(String? payload) async {
    unawaited(CrashReportingService.instance.breadcrumb('reminder: opened'));
    try {
      final data = jsonDecode(payload ?? '') as Map;
      final user = FirebaseAuth.instance.currentUser?.uid;
      if (user == null || data['user'] != user) {
        _message(lookupAppLocalizations(LanguageController.instance.locale)
            .signInToTheReminderSAccountToViewThisCar);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('cars')
          .doc(user)
          .collection('user_cars')
          .doc(data['car'] as String)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 20));
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user) return;
      if (!doc.exists) {
        _message(lookupAppLocalizations(LanguageController.instance.locale)
            .thisCarHasBeenRemoved);
        return;
      }
      _navigator.currentState?.push(MaterialPageRoute(
          settings: const RouteSettings(name: 'car_editor'),
          builder: (_) =>
              AddOrEditCarScreen(car: Car.fromMap(doc.data()!, doc.id))));
    } catch (error, stack) {
      unawaited(CrashReportingService.instance
          .report(error, stack, operation: 'open_reminder'));
      _message(lookupAppLocalizations(LanguageController.instance.locale)
          .couldNotOpenThisCarPleaseCheckYourCars);
    }
  }

  void _message(String message) =>
      _messenger.currentState?.showSnackBar(SnackBar(content: Text(message)));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth?.cancel();
    LanguageController.instance.removeListener(_languageChanged);
    _notifications.onTap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [AppearanceController.instance, LanguageController.instance]),
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigator,
        navigatorObservers: [_crashNavigation],
        scaffoldMessengerKey: _messenger,
        title: 'CarAlerts',
        locale: LanguageController.instance.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppearanceController.instance.mode,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemBars(Theme.of(context).brightness),
          child: child!,
        ),
        home: StreamBuilder(
          stream: _authState,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            } else if (snapshot.hasData) {
              if (_renderedUser != snapshot.data!.uid) {
                _renderedUser = snapshot.data!.uid;
                mainScreenKey = GlobalKey<MainScreenState>();
              }
              return MainScreen();
            } else {
              return const SignInScreen();
            }
          },
        ),
      ),
    );
  }
}
