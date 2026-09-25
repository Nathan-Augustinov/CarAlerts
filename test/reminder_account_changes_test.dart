import 'dart:async';
import 'dart:convert';
import 'package:car_alerts/services/reminder_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class MemoryReminders extends ReminderBackend {
  @override
  String? user = 'a';
  @override
  int? limit;
  Map<String, Map<String, dynamic>> savedCars = {};
  Map<int, String?> requests = {};
  Map<String, int> ids = {};
  Map<String, String> history = {};
  final shown = <Reminder>[];
  final cancelled = <int>[];
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> enabled() async => true;
  @override
  Future<tz.Location> timezone() async => tz.UTC;
  @override
  Future<Map<String, Map<String, dynamic>>> cars(String user) async =>
      savedCars;
  @override
  Future<Map<int, String?>> pending() async => Map.of(requests);
  @override
  Future<Map<String, int>> loadIds() async => Map.of(ids);
  @override
  Future<void> saveIds(Map<String, int> value) async => ids = Map.of(value);
  @override
  Future<Map<String, String>> loadHistory() async => Map.of(history);
  @override
  Future<void> saveHistory(Map<String, String> value) async =>
      history = Map.of(value);
  @override
  Future<void> show(int id, Reminder reminder) async => shown.add(reminder);
  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    requests.remove(id);
  }

  @override
  Future<void> schedule(int id, Reminder reminder) async =>
      requests[id] = reminder.payload;
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('invalid dates do not block valid schedules or catch-up reminders',
      () async {
    final backend = MemoryReminders();
    backend.savedCars = {
      'BAD': {'insurance_date': 'invalid'},
      'GOOD': {
        'inspection_date': '2030-08-01',
        'custom_expiries': {
          'bad': {'name': 'Broken', 'expiry_date': 'invalid'},
          'good': {'name': 'Permit', 'expiry_date': '2030-07-02'},
        },
      },
    };
    final stale = Reminder(
        'a', 'BAD', 'insurance_date', 1, tz.TZDateTime(tz.UTC, 2030, 7, 3, 9));
    backend.requests[99] = stale.payload;
    final coordinator = ReminderCoordinator(backend,
        now: () => tz.TZDateTime(tz.UTC, 2030, 7, 1, 12));
    expect(
        await coordinator.refresh(
            savedUser: 'a',
            savedCar: 'GOOD',
            savedDates: backend.savedCars['GOOD']),
        ReminderStatus.ready);
    expect(backend.cancelled, contains(99));
    expect(backend.requests, hasLength(3));
    expect(backend.shown.single.category, 'custom:good');
  });

  test('rename replaces old schedules without replaying a delivered catch-up',
      () async {
    final backend = MemoryReminders();
    final now = tz.TZDateTime(tz.UTC, 2026, 9, 23, 12);
    final old = Reminder('a', 'OLD', 'inspection_date', 30,
        tz.TZDateTime(tz.UTC, 2026, 10, 1, 9));
    backend.ids[old.key] = 44;
    backend.requests[44] = old.payload;
    final oldHistory = jsonEncode(['a', 'OLD', 'insurance_date', '2026-09-24']);
    backend.history[oldHistory] = 'shown';
    backend.savedCars['NEW'] = {
      'insurance_date': '2026-09-24',
      'inspection_date': '2026-10-31',
    };
    final coordinator = ReminderCoordinator(backend, now: () => now);
    expect(
        await coordinator.refresh(
            savedUser: 'a',
            savedCar: 'NEW',
            renamedFrom: 'OLD',
            savedDates: backend.savedCars['NEW']),
        ReminderStatus.ready);
    expect(backend.shown, isEmpty);
    expect(backend.cancelled, contains(44));
    expect(backend.requests, hasLength(3));
    for (final payload in backend.requests.values) {
      expect(jsonDecode(payload!)['car'], 'NEW');
    }
    expect(backend.history.containsKey(oldHistory), isFalse);
    expect(
        backend
            .history[jsonEncode(['a', 'NEW', 'insurance_date', '2026-09-24'])],
        'shown');
    await coordinator.refresh(
        savedUser: 'a',
        savedCar: 'NEW',
        renamedFrom: 'OLD',
        savedDates: backend.savedCars['NEW']);
    expect(backend.shown, isEmpty);
    expect(backend.requests, hasLength(3));
  });

  test(
      'account cleanup serializes scheduling and a failure leaves queue usable',
      () async {
    final backend = MemoryReminders();
    final coordinator = ReminderCoordinator(backend);
    final gate = Completer<void>();
    var refreshed = false;
    final cleanup = coordinator.exclusive(() async {
      await gate.future;
      throw StateError('Cleanup failed');
    });
    final expectedFailure = expectLater(cleanup, throwsStateError);
    final refresh = coordinator.refresh().then((_) => refreshed = true);
    await Future<void>.delayed(Duration.zero);
    expect(refreshed, isFalse);
    gate.complete();
    await expectedFailure;
    await refresh;
    expect(refreshed, isTrue);
  });
}
