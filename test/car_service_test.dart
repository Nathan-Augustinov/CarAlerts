import 'package:car_alerts/services/car_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stale editor preserves concurrent dates and custom expiry fields',
      () async {
    final db = FakeFirebaseFirestore();
    final service = CarService(firestore: db);
    final doc = db.doc('cars/a/user_cars/CAR');
    final original = <String, dynamic>{
      'insurance_date': '2090-01-01',
      'inspection_date': '2090-02-01',
      'custom_expiries': {
        'one': {'name': 'Permit', 'expiry_date': '2090-03-01'},
        'remove': {'name': 'Remove', 'expiry_date': '2090-04-01'},
      },
    };
    await doc.set({
      ...original,
      'insurance_date': '2091-01-01',
      'custom_expiries': {
        'one': {'name': 'Updated permit', 'expiry_date': '2090-03-01'},
        'remove': {'name': 'Remove', 'expiry_date': '2090-04-01'},
        'remote': {'name': 'Remote addition', 'expiry_date': '2090-05-01'},
      },
    });
    final saved = await service.save(
        userId: 'a',
        registration: 'RENAMED',
        previousRegistration: 'CAR',
        originalDates: original,
        dates: {
          ...original,
          'inspection_date': null,
          'custom_expiries': {
            'one': {'name': 'Permit', 'expiry_date': '2092-03-01'},
          },
        });
    expect(saved['insurance_date'], '2091-01-01');
    expect(saved['inspection_date'], isNull);
    expect(saved['custom_expiries'], {
      'one': {'name': 'Updated permit', 'expiry_date': '2092-03-01'},
      'remote': {'name': 'Remote addition', 'expiry_date': '2090-05-01'},
    });
    expect((await db.doc('cars/a/user_cars/RENAMED').get()).data(), saved);
    expect((await doc.get()).exists, isFalse);
  });

  late FakeFirebaseFirestore db;
  late CarService service;
  const oldDates = {
    'insurance_date': '2027-03-01',
    'inspection_date': '2027-05-01'
  };
  setUp(() {
    db = FakeFirebaseFirestore();
    service = CarService(firestore: db);
  });

  test('rename moves the car, preserves fields and leaves other users alone',
      () async {
    await db.doc('cars/a/user_cars/OLD').set({...oldDates, 'metadata': 42});
    await db.doc('cars/b/user_cars/OLD').set(oldDates);
    await service.save(
        userId: 'a',
        registration: 'NEW',
        previousRegistration: 'OLD',
        dates: {'insurance_date': '2028-03-01'});
    expect((await db.doc('cars/a/user_cars/OLD').get()).exists, isFalse);
    expect((await db.doc('cars/a/user_cars/NEW').get()).data(), {
      ...oldDates,
      'insurance_date': '2028-03-01',
      'metadata': 42,
    });
    expect((await db.doc('cars/b/user_cars/OLD').get()).data(), oldDates);
    expect((await db.collection('cars/a/user_cars').get()).docs, hasLength(1));
  });

  test('renaming to an existing registration cannot overwrite either car',
      () async {
    await db.doc('cars/a/user_cars/OLD').set(oldDates);
    await db.doc('cars/a/user_cars/NEW').set({'insurance_date': '2030-01-01'});
    await expectLater(
        service.save(
            userId: 'a',
            registration: 'NEW',
            previousRegistration: 'OLD',
            dates: {}),
        throwsA(isA<CarSaveException>()));
    expect((await db.doc('cars/a/user_cars/OLD').get()).data(), oldDates);
    expect((await db.doc('cars/a/user_cars/NEW').get()).data(),
        {'insurance_date': '2030-01-01'});
  });

  test('new car duplicate is rejected, same-registration edit succeeds',
      () async {
    await db.doc('cars/a/user_cars/OLD').set(oldDates);
    await expectLater(service.save(userId: 'a', registration: 'OLD', dates: {}),
        throwsA(isA<CarSaveException>()));
    await service.save(
        userId: 'a',
        registration: 'OLD',
        previousRegistration: 'OLD',
        dates: {'insurance_date': null});
    expect((await db.doc('cars/a/user_cars/OLD').get()).data(),
        {...oldDates, 'insurance_date': null});
  });

  test('stale edit cannot recreate a deleted or renamed car', () async {
    for (final destination in ['OLD', 'NEW']) {
      await expectLater(
          service.save(
              userId: 'a',
              registration: destination,
              previousRegistration: 'OLD',
              dates: oldDates),
          throwsA(isA<CarSaveException>()));
    }
    expect((await db.collection('cars/a/user_cars').get()).docs, isEmpty);
  });

  test('invalid document names cannot reach database writes', () async {
    for (final name in ['', ' ', '/', 'AA/BB', '.', '..']) {
      await expectLater(
          service.save(userId: 'a', registration: name, dates: {}),
          throwsA(isA<CarSaveException>()));
    }
    expect((await db.collection('cars/a/user_cars').get()).docs, isEmpty);
  });
}
