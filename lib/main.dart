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
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<User?>? _auth;
  String? _renderedUser;
  final _notifications = NotificationsService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications.onTap = _openReminder;
    _auth = FirebaseAuth.instance.authStateChanges().listen((_) {
      _navigator.currentState?.popUntil((route) => route.isFirst);
      _refresh();
    });
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
    try {
      final data = jsonDecode(payload ?? '') as Map;
      final user = FirebaseAuth.instance.currentUser?.uid;
      if (user == null || data['user'] != user) {
        _message('Sign in to the reminder’s account to view this car.');
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
        _message('This car has been removed.');
        return;
      }
      _navigator.currentState?.push(MaterialPageRoute(
          builder: (_) =>
              AddOrEditCarScreen(car: Car.fromMap(doc.data()!, doc.id))));
    } catch (_) {
      _message('Could not open this car. Please check Your cars.');
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
    _notifications.onTap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      scaffoldMessengerKey: _messenger,
      title: 'Car Alerts',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
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
    );
  }
}
