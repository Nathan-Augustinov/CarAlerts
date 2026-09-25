import 'crash_reporting_service.dart';
import 'user_settings_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Account language; absent and unsupported values use English.
class LanguageController extends ChangeNotifier {
  LanguageController({FirebaseFirestore? firestore}) : _firestore = firestore;
  static final instance = LanguageController();
  final FirebaseFirestore? _firestore;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  String? _user;
  int _binding = 0;
  Locale _locale = const Locale('en');
  bool _saving = false;
  Locale get locale => _locale;
  bool get saving => _saving;

  DocumentReference<Map<String, dynamic>> _settings(String uid) =>
      (_firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('user_settings');

  void bindUser(String? uid) {
    if (_user == uid) return;
    _subscription?.cancel();
    final binding = ++_binding;
    _user = uid;
    _locale = const Locale('en');
    _saving = false;
    notifyListeners();
    if (uid == null) return;
    unawaited(UserSettingsService(firestore: _firestore)
        .initializeForUser(uid)
        .catchError((Object error, StackTrace stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'initialize_language');
    }));
    _subscription = _settings(uid).snapshots().listen((snapshot) {
      if (_binding != binding) return;
      final code = snapshot.data()?['language'];
      _locale = Locale(code == 'ro' ? 'ro' : 'en');
      notifyListeners();
    }, onError: (Object error, StackTrace stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'load_language');
      // Retain the last known language while offline or unable to read.
    });
  }

  Future<void> select(String code) async {
    if (!const ['en', 'ro'].contains(code)) throw ArgumentError.value(code);
    final uid = _user;
    if (uid == null) throw StateError('No signed-in account');
    if (_saving) return;
    final binding = _binding;
    final previous = _locale;
    _saving = true;
    notifyListeners();
    try {
      await _settings(uid).set({'language': code}, SetOptions(merge: true));
      if (_binding == binding) _locale = Locale(code);
    } catch (_) {
      if (_binding == binding) _locale = previous;
      rethrow;
    } finally {
      if (_binding == binding) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _binding++;
    _subscription?.cancel();
    super.dispose();
  }
}
