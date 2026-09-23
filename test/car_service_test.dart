import 'package:car_alerts/services/car_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
