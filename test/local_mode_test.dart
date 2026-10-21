import 'package:car_alerts/services/reminder_target.dart';
import 'dart:async';
import 'dart:convert';
import 'package:car_alerts/services/local_car_store.dart';
import 'package:car_alerts/services/local_car_transfer.dart';
import 'package:car_alerts/services/car_store.dart';
import 'package:car_alerts/services/car_service.dart';
import 'package:car_alerts/services/session_route.dart';
import 'package:car_alerts/services/reminder_coordinator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'reminder_account_changes_test.dart' show MemoryReminders;

class TestFirestore extends FakeFirebaseFirestore {
  bool fail = false;
  Future<void> Function()? afterCommit;
  Completer<void>? gate;
  @override
  Future<T> runTransaction<T>(TransactionHandler<T> handler,
      {Duration timeout = const Duration(seconds: 30),
      int maxAttempts = 5}) async {
    await gate?.future;
    if (fail) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    final result = await super.runTransaction(handler);
    await afterCommit?.call();
    return result;
  }
}

void main() {
  late String disk;
  late bool failDisk;
  late LocalCarStore local;
  late TestFirestore db;
  String? user;
  const dates = {
    'insurance_date': '2090-03-01',
    'inspection_date': '2091-04-02'
  };
  LocalCarStore restart() => LocalCarStore(
      read: () async => disk,
      write: (s) async {
        if (failDisk) throw StateError('Disk full');
        disk = s;
      });
  LocalCarTransfer transfer() =>
      LocalCarTransfer(local: local, firestore: db, currentUser: () => user);
  SessionRoute route() => sessionRoute(
      user: user,
      localActive: local.active,
      hasLocalCar: local.registration != null);
  setUp(() async {
    disk = '{}';
    failDisk = false;
    user = null;
    local = restart();
    await local.load();
    db = TestFirestore();
  });
  setUpAll(tzdata.initializeTimeZones);

  test('offline CRUD, rename, custom dates, and persistence across restart',
      () async {
    await local.save(registration: 'CAR', dates: {
      ...dates,
      'custom_expiries': {
        'a': {'name': 'Permit', 'expiry_date': '2092-01-01'}
      }
    });
    local = restart();
    await local.load();
    expect(local.active, isTrue);
    final original = local.dates!;
    await local.save(
        registration: 'RENAMED',
        previousRegistration: 'CAR',
        originalDates: original,
        dates: {...original, 'insurance_date': null});
    local = restart();
    await local.load();
    expect(local.registration, 'RENAMED');
    expect(local.dates!['insurance_date'], isNull);
    expect(local.dates!['custom_expiries'], original['custom_expiries']);
    await local.delete();
    local = restart();
    await local.load();
    expect(local.cars, isEmpty);
    expect(local.active, isFalse);
  });
  test(
      'concurrent additions enforce one car, failed persistence publishes nothing',
      () async {
    final one = local.save(registration: 'ONE', dates: dates);
    final two = local.save(registration: 'TWO', dates: dates);
    await one;
    await expectLater(two, throwsA(isA<LocalCarLimitException>()));
    final before = disk;
    failDisk = true;
    await expectLater(local.delete(), throwsStateError);
    expect(disk, before);
    expect(local.registration, 'ONE');
    failDisk = false;
    await local.delete();
    await local.save(registration: 'TWO', dates: dates);
    expect(local.registration, 'TWO');
  });
  test('local store reuses registration, expiry, and custom validation',
      () async {
    await expectLater(local.save(registration: '/', dates: dates),
        throwsA(isA<CarSaveException>()));
    await expectLater(
        local
            .save(registration: 'CAR', dates: {'insurance_date': '2000-01-01'}),
        throwsA(isA<CarSaveException>()));
    await expectLater(
        local.save(registration: 'CAR', dates: {
          'custom_expiries': {
            'a': {'name': '', 'expiry_date': '2090-01-01'}
          }
        }),
        throwsA(isA<CarSaveException>()));
    expect(local.cars, isEmpty);
  });
  test(
      'startup priority, empty local entry, explicit sign-out, and pending recovery',
      () async {
    expect(route(), SessionRoute.signIn);
    await local.enter();
    expect(route(), SessionRoute.local);
    await local.save(registration: 'CAR', dates: dates);
    user = 'a';
    expect(route(), SessionRoute.transfer);
    await local.signOut();
    user = null;
    expect(route(), SessionRoute.signIn);
    local = restart();
    await local.load();
    expect(route(), SessionRoute.signIn);
    expect(local.registration, 'CAR');
    await local.enter();
    expect(route(), SessionRoute.local);
    user = 'a';
    expect(route(), SessionRoute.transfer);
    await transfer().move('a');
    expect(route(), SessionRoute.account);
  });
  test('successful transfer retains all dates and other account cars',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    await db.doc('cars/a/user_cars/OTHER').set(dates);
    await db.doc('cars/b/user_cars/CAR').set({'inspection_date': '2099-01-01'});
    user = 'a';
    await transfer().move('a');
    expect(local.cars, isEmpty);
    expect((await db.doc('cars/a/user_cars/CAR').get()).data(), dates);
    expect((await db.collection('cars/a/user_cars').get()).docs, hasLength(2));
    expect(
        (await db.doc('cars/b/user_cars/CAR').get()).data()?['inspection_date'],
        '2099-01-01');
  });
  test(
      'identical account data completes without a conflict and records receipt',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    await db.doc('cars/a/user_cars/CAR').set(dates);
    final token = local.token!;
    user = 'a';
    expect(await transfer().move('a'), TransferResult.alreadyPresent);
    expect(local.cars, isEmpty);
    expect((await db.doc('cars/a/user_cars/CAR').get()).data(), dates);
    expect(
        (await db.doc('users/a/settings/user_settings').get())
            .data()?['_localTransfers'][token],
        true);
  });
  test(
      'identical transfer cleanup failure can retry without overwriting account edits',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    await db.doc('cars/a/user_cars/CAR').set(dates);
    user = 'a';
    failDisk = true;
    await expectLater(transfer().move('a'), throwsStateError);
    expect(local.dates, dates);
    await db
        .doc('cars/a/user_cars/CAR')
        .update({'insurance_date': '2099-01-01'});
    failDisk = false;
    await transfer().move('a');
    expect(local.cars, isEmpty);
    expect(
        (await db.doc('cars/a/user_cars/CAR').get()).data()?['insurance_date'],
        '2099-01-01');
  });
  test('network failure preserves local copy and safe retry succeeds',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    user = 'a';
    db.fail = true;
    await expectLater(transfer().move('a'), throwsA(isA<FirebaseException>()));
    expect(local.dates, dates);
    db.fail = false;
    await transfer().move('a');
    expect(local.cars, isEmpty);
    expect((await db.collection('cars/a/user_cars').get()).docs, hasLength(1));
  });
  test('interrupted cleanup retries without overwriting later account edits',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    user = 'a';
    failDisk = true;
    await expectLater(transfer().move('a'), throwsStateError);
    expect(local.dates, dates);
    await db
        .doc('cars/a/user_cars/CAR')
        .update({'insurance_date': '2099-02-01'});
    failDisk = false;
    local = restart();
    await local.load();
    await transfer().move('a');
    expect(
        (await db.doc('cars/a/user_cars/CAR').get()).data()?['insurance_date'],
        '2099-02-01');
    expect(local.cars, isEmpty);
  });
  test('receipt survives later rename or deletion and never recreates a car',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    user = 'a';
    failDisk = true;
    await expectLater(transfer().move('a'), throwsStateError);
    await db.doc('cars/a/user_cars/CAR').delete();
    failDisk = false;
    await transfer().move('a');
    expect((await db.collection('cars/a/user_cars').get()).docs, isEmpty);
    expect(local.cars, isEmpty);
  });
  for (final keepAccount in [true, false]) {
    test(
        'duplicate choice keepAccount=$keepAccount checks the displayed snapshot',
        () async {
      await local.save(registration: 'CAR', dates: dates);
      user = 'a';
      const accountDates = {'insurance_date': '2095-01-01'};
      await db.doc('cars/a/user_cars/CAR').set(accountDates);
      await expectLater(transfer().move('a'), throwsA(isA<TransferConflict>()));
      expect(local.dates, dates);
      await transfer()
          .move('a', expected: accountDates, keepAccount: keepAccount);
      expect((await db.doc('cars/a/user_cars/CAR').get()).data(),
          keepAccount ? accountDates : dates);
      expect(local.cars, isEmpty);
    });
    test('concurrent cloud edit requires a new choice keepAccount=$keepAccount',
        () async {
      await local.save(registration: 'CAR', dates: dates);
      user = 'a';
      await db
          .doc('cars/a/user_cars/CAR')
          .set({'insurance_date': '2096-01-01'});
      await expectLater(
          transfer().move('a',
              expected: {'insurance_date': '2095-01-01'},
              keepAccount: keepAccount),
          throwsA(isA<TransferConflict>()));
      expect(local.dates, dates);
      expect(
          (await db.doc('cars/a/user_cars/CAR').get())
              .data()?['insurance_date'],
          '2096-01-01');
    });
  }
  test('account change after commit preserves local and isolates receipts',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    user = 'a';
    db.afterCommit = () async => user = 'b';
    await expectLater(transfer().move('a'), throwsStateError);
    expect(local.dates, dates);
    expect((await db.collection('cars/b/user_cars').get()).docs, isEmpty);
    db.afterCommit = null;
    user = 'a';
    await transfer().move('a');
    expect(local.cars, isEmpty);
  });
  test('repeated submission is rejected while transaction is running',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    user = 'a';
    db.gate = Completer<void>();
    final service = transfer();
    final first = service.move('a');
    await expectLater(service.move('a'), throwsStateError);
    db.gate!.complete();
    await first;
    expect((await db.collection('cars/a/user_cars').get()).docs, hasLength(1));
  });
  test('explicit local deletion leaves cloud car and settings untouched',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    await db.doc('cars/a/user_cars/CAR').set(dates);
    final before = db.dump();
    await local.delete();
    expect(db.dump(), before);
    expect(local.cars, isEmpty);
  });
  test(
      'signed-in shared store still supports multiple cars and isolated deletion',
      () async {
    final store = CarStore('a', firestore: db);
    await store.save(registration: 'ONE', dates: dates);
    await store.save(registration: 'TWO', dates: dates);
    expect(await store.read(), hasLength(2));
    await store.delete('ONE');
    expect((await store.read()).keys, ['TWO']);
  });
  test('local notification taps open offline car and reject other identities',
      () async {
    await local.save(registration: 'CAR', dates: dates);
    String? owner = localOwner;
    final payload = jsonEncode({'user': localOwner, 'car': 'CAR'});
    final car = await reminderTarget(payload,
        currentOwner: () => owner, read: (_) async => local.cars);
    expect(car!.name, 'CAR');
    expect(car.items, dates);
    owner = 'a';
    await expectLater(
        reminderTarget(payload,
            currentOwner: () => owner,
            read: (_) async => throw StateError('Must not fetch')),
        throwsA(isA<ReminderOwnerMismatch>()));
    owner = localOwner;
    await expectLater(
        reminderTarget(payload,
            currentOwner: () => owner,
            read: (_) async {
              owner = 'a';
              return local.cars;
            }),
        throwsA(isA<ReminderOwnerMismatch>()));
    owner = localOwner;
    await local.delete();
    expect(
        await reminderTarget(payload,
            currentOwner: () => owner, read: (_) async => local.cars),
        isNull);
  });
  test(
      'offline local reminders refresh after edits, delete, and transfer without duplicates',
      () async {
    final backend = MemoryReminders()..user = localOwner;
    final coordinator = ReminderCoordinator(backend,
        now: () => tz.TZDateTime(tz.UTC, 2089, 1, 1));
    await local.save(registration: 'CAR', dates: dates);
    backend.savedCars = local.cars;
    expect(await coordinator.refresh(), ReminderStatus.ready);
    expect(backend.requests, hasLength(6));
    expect(jsonDecode(backend.requests.values.first!)['user'], localOwner);
    await local.save(
        registration: 'CAR',
        previousRegistration: 'CAR',
        dates: {'insurance_date': null});
    backend.savedCars = local.cars;
    await coordinator.refresh();
    expect(backend.requests, hasLength(3));
    backend.user = 'a';
    await coordinator.refresh();
    expect(backend.requests, hasLength(3));
    for (final payload in backend.requests.values) {
      expect(jsonDecode(payload!)['user'], 'a');
    }
    backend.user = localOwner;
    await local.delete();
    backend.savedCars = local.cars;
    await coordinator.refresh();
    expect(backend.requests, isEmpty);
  });
}
