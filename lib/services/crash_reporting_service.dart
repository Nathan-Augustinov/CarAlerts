import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class CrashSink {
  Future<void> collection(bool enabled);
  Future<void> discard();
  Future<void> user(String id);
  Future<void> key(String name, String value);
  Future<void> log(String message);
  Future<void> error(
      String description, StackTrace stack, String operation, bool fatal);
}

class FirebaseCrashSink implements CrashSink {
  FirebaseCrashlytics get sdk => FirebaseCrashlytics.instance;
  @override
  Future<void> collection(bool enabled) =>
      sdk.setCrashlyticsCollectionEnabled(enabled);
  @override
  Future<void> discard() => sdk.deleteUnsentReports();
  @override
  Future<void> user(String id) => sdk.setUserIdentifier(id);
  @override
  Future<void> key(String name, String value) => sdk.setCustomKey(name, value);
  @override
  Future<void> log(String message) => sdk.log(message);
  @override
  Future<void> error(
          String description, StackTrace stack, String operation, bool fatal) =>
      sdk.recordError(description, stack,
          reason: operation, fatal: fatal, printDetails: false);
}

/// Only controlled labels belong in breadcrumbs, never form values or payloads.
class CrashReportingService {
  CrashReportingService({CrashSink? sink, DateTime Function()? now})
      : _sink = sink ?? FirebaseCrashSink(),
        _now = now ?? DateTime.now;
  static final instance = CrashReportingService();
  static const localTesting = bool.fromEnvironment('ENABLE_CRASHLYTICS');
  static const testControls = !kReleaseMode && localTesting;
  final CrashSink _sink;
  final DateTime Function() _now;
  bool _enabled = false;
  String _user = '';
  String _screen = 'startup';
  Future<void> _tail = Future.value();
  final Map<String, DateTime> _recent = {};

  Future<void> initialize({bool enabled = kReleaseMode || localTesting}) async {
    _enabled = false;
    await _safe(() async {
      if (!enabled) {
        await _sink.collection(false);
        await _sink.discard();
        return;
      }
      await _sink.key(
          'environment', kReleaseMode ? 'release' : 'development_test');
      await _sink.key('screen', _screen);
      await _sink.user(_user);
      await _sink.collection(true);
      _enabled = true;
    });
  }

  void installHandlers() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      unawaited(report(details.exception, details.stack ?? StackTrace.current,
          operation: 'flutter_framework', fatal: true));
    };
    final previousAsync = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(report(error, stack, operation: 'uncaught_async', fatal: true));
      return previousAsync?.call(error, stack) ?? _enabled;
    };
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Reporting must never fail an app operation or recursively report itself.
      debugPrint('Crash reporting unavailable.');
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    _tail = _tail.then((_) => _safe(action));
    return _tail;
  }

  Future<void> setUser(String? uid) {
    _user = uid ?? '';
    _recent.clear();
    final id = _user;
    return _enabled ? _enqueue(() => _sink.user(id)) : Future.value();
  }

  Future<void> screen(String name) {
    if (_screen == name) return Future.value();
    _screen = name;
    if (!_enabled) return Future.value();
    return _enqueue(() async {
      await _sink.key('screen', name);
      await _sink.log('screen: $name');
    });
  }

  Future<void> breadcrumb(String event) =>
      _enabled ? _enqueue(() => _sink.log(event)) : Future.value();

  static bool isExpected(Object error) {
    if (error is GoogleSignInException) {
      return error.code == GoogleSignInExceptionCode.canceled;
    }
    if (error is FirebaseException && error.plugin == 'firebase_auth') {
      return const {
        'invalid-email',
        'invalid-credential',
        'wrong-password',
        'user-not-found',
        'email-already-in-use',
        'weak-password',
        'password-does-not-meet-requirements',
        'missing-password',
        'user-mismatch',
        'requires-recent-login',
        'user-disabled',
        'too-many-requests'
      }.contains(error.code);
    }
    return error is PlatformException && error.code == 'email_unavailable';
  }

  Future<void> report(Object error, StackTrace stack,
      {required String operation, bool fatal = false}) {
    if (!_enabled || (!fatal && isExpected(error))) return Future.value();
    // Exception messages may embed email addresses, plates or database paths.
    // Keep the original stack and stable type/code, not arbitrary message text.
    final description = error is FirebaseException
        ? '${error.runtimeType} [${error.plugin}/${error.code}]'
        : error is PlatformException
            ? 'PlatformException [${error.code}]'
            : error is GoogleSignInException
                ? 'GoogleSignInException [${error.code.name}]'
                : error.runtimeType.toString();
    final now = _now();
    _recent.removeWhere(
        (_, time) => now.difference(time) >= const Duration(minutes: 1));
    final fingerprint =
        '$_user|$operation|$description|${stack.toString().split('\n').first}';
    if (!fatal && _recent.containsKey(fingerprint)) return Future.value();
    if (_recent.length >= 100) _recent.remove(_recent.keys.first);
    _recent[fingerprint] = now;
    final screen = _screen;
    return _enqueue(() async {
      await _sink.key('screen', screen);
      await _sink.key('operation', operation);
      await _sink.log('failed: $operation');
      await _sink.error(description, stack, operation, fatal);
    });
  }
}
