import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'car_service.dart';

// A slash cannot occur in a Firebase UID/document identity used by this app.
const localOwner = 'device/local';

class LocalCarLimitException implements Exception {}

/// One atomic native record, separate from Firebase and account preferences.
/// Mutations are serialized, persisted first, then published to readers.
class LocalCarStore extends ChangeNotifier {
  LocalCarStore({required this.read, required this.write});
  static const channel = MethodChannel('car_alerts/notification_permissions');
  static final instance = LocalCarStore(
    read: () async =>
        await channel.invokeMethod<String>('loadLocalData') ?? '{}',
    write: (value) => channel.invokeMethod<void>('saveLocalData', value),
  );
  final Future<String> Function() read;
  final Future<void> Function(String) write;
  Map<String, dynamic> _record = {};
  Future<void> _tail = Future.value();
  bool active = false;
  String? get registration => _record['registration'] as String?;
  String? get token => _record['token'] as String?;
  String? get language => _record['language'] as String?;
  bool get signedOut => _record['signedOut'] == true;
  Map<String, dynamic>? get dates => _record['dates'] == null
      ? null
      : Map<String, dynamic>.from(
          jsonDecode(jsonEncode(_record['dates'])) as Map);
  Map<String, Map<String, dynamic>> get cars =>
      registration == null ? {} : {registration!: dates!};
  Future<void> load() async {
    _record = Map<String, dynamic>.from(jsonDecode(await read()) as Map);
    active = registration != null && !signedOut;
    notifyListeners();
  }

  Future<T> exclusive<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _persist(Map<String, dynamic> next) async {
    final encoded = jsonEncode(next);
    await write(encoded);
    _record = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
    notifyListeners();
  }

  Future<void> enter() async {
    await exclusive(() => _persist({..._record, 'signedOut': false}));
    active = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await exclusive(() => _persist({..._record, 'signedOut': true}));
    active = false;
    notifyListeners();
  }

  Future<void> setLanguage(String value) =>
      exclusive(() => _persist({..._record, 'language': value}));
  Future<Map<String, dynamic>> save(
          {required String registration,
          required Map<String, dynamic> dates,
          String? previousRegistration,
          Map<String, dynamic>? originalDates}) =>
      exclusive(() async {
        final name = registration.trim();
        if (name.isEmpty || name.contains('/') || name == '.' || name == '..') {
          throw const CarSaveException('Enter a valid registration number.');
        }
        if (this.registration != null && previousRegistration == null) {
          throw LocalCarLimitException();
        }
        if (previousRegistration != null &&
            previousRegistration != this.registration) {
          throw const CarSaveException(
              'This car has been removed or renamed. Reopen it from Your cars.');
        }
        final existing = this.dates ?? {};
        final updated = originalDates == null
            ? {...existing, ...dates}
            : applyCarChanges(existing, originalDates, dates);
        validateCarDates(updated, existing, name);
        // A new revision gets a new transfer token. Retries of this revision reuse it.
        final token = List.generate(
            24,
            (_) => Random.secure()
                .nextInt(256)
                .toRadixString(16)
                .padLeft(2, '0')).join();
        await _persist({
          ..._record,
          'registration': name,
          'dates': updated,
          'token': token
        });
        return updated;
      });
  Future<void> delete({String? expectedToken}) => exclusive(() async {
        if (expectedToken != null && token != expectedToken) {
          throw StateError('Local car changed');
        }
        final next = {..._record}
          ..remove('registration')
          ..remove('dates')
          ..remove('token');
        await _persist(next);
      });
  Stream<Map<String, Map<String, dynamic>>> watch() => Stream.multi((sink) {
        void emit() => sink.add(cars);
        addListener(emit);
        emit();
        sink.onCancel = () => removeListener(emit);
      });
}
