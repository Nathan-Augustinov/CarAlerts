import 'package:car_alerts/models/car.dart';
import 'package:car_alerts/models/expiry_validation.dart';
import 'package:car_alerts/services/reminder_coordinator.dart';
import 'package:car_alerts/services/car_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('past dates require the same original calendar day; today is allowed',
      () {
    final now = DateTime(2030, 6, 10, 15);
    expect(validateExpiryDate(DateTime(2030, 6, 10), now: now), isNull);
    expect(validateExpiryDate(DateTime(2030, 6, 9), now: now), isNotNull);
    expect(
        validateExpiryDate(DateTime(2030, 6, 9),
            original: '2030-06-09T00:00:00.000', now: now),
        isNull);
    expect(
        validateExpiryDate(DateTime(2030, 6, 8),
            original: '2030-06-09', now: now),
        isNotNull);
  });

  test('custom names and dates reach displays and all reminder intervals', () {
    tzdata.initializeTimeZones();
    final data = {
      'custom_expiries': {
        'stable': {
          'name': 'Parking permit',
          'expiry_date': '2030-08-01T00:00:00.000'
        }
      }
    };
    final car = Car.fromMap(data, 'CAR');
    expect(car.allItems['custom:stable'], '2030-08-01T00:00:00.000');
    expect(car.itemLabel('custom:stable'), 'Parking permit');
    final reminders =
        planReminders('user', {'CAR': data}, tz.UTC, DateTime.utc(2030, 6));
    expect(reminders.map((r) => r.advance), [30, 7, 1]);
    expect(reminders.every((r) => r.title == 'CAR · Parking permit'), isTrue);
    final renamed = {
      'custom_expiries': {
        'stable': {
          'name': 'Permit renewed',
          'expiry_date': '2030-08-01T00:00:00.000'
        }
      }
    };
    final next =
        planReminders('user', {'CAR': renamed}, tz.UTC, DateTime.utc(2030, 6));
    expect(next.first.key, reminders.first.key);
    expect(next.first.payload, isNot(reminders.first.payload));
    expect(
        lateReminders(
                'user', 'CAR', data, tz.UTC, DateTime.utc(2030, 7, 31, 12))
            .single
            .title,
        'CAR · Parking permit');
  });

  test(
      'save preserves overdue entries and replaces custom map on removal and rename',
      () async {
    final db = FakeFirebaseFirestore();
    final service = CarService(firestore: db);
    await db.doc('cars/u/user_cars/OLD').set({
      'insurance_date': '2020-01-01',
      'custom_expiries': {
        'id': {'name': 'Permit', 'expiry_date': '2020-01-01'}
      }
    });
    await service.save(
        userId: 'u',
        registration: 'OLD',
        previousRegistration: 'OLD',
        dates: {});
    await service.save(
        userId: 'u',
        registration: 'NEW',
        previousRegistration: 'OLD',
        dates: {'custom_expiries': <String, dynamic>{}});
    expect(
        (await db.doc('cars/u/user_cars/NEW').get()).data()!['custom_expiries'],
        isEmpty);
    expect((await db.doc('cars/u/user_cars/OLD').get()).exists, isFalse);
    await expectLater(
        service.save(
            userId: 'u',
            registration: 'NEW',
            previousRegistration: 'NEW',
            dates: {'inspection_date': '2020-01-01'}),
        throwsA(isA<CarSaveException>()));
  });

  test('new car with Oil change tomorrow and unselected built-in dates saves', () async {
    final db = FakeFirebaseFirestore();
    final service = CarService(firestore: db);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    final data = <String, dynamic>{
      'custom_expiries': {
        'id': {'name': 'Oil change', 'expiry_date': tomorrow},
      },
      'insurance_date': null,
      'inspection_date': null,
      'romanian_vignette_date': null,
      'hungarian_vignette_date': null,
      'austrian_vignette_date': null,
    };
    await service.save(userId: 'u', registration: 'CAR', dates: data);
    expect((await db.doc('cars/u/user_cars/CAR').get()).data(), data);
  });

  test('save rejects duplicate names and more than ten custom expiries',
      () async {
    final service = CarService(firestore: FakeFirebaseFirestore());
    for (final names in [
      ['Permit', ' permit '],
      List.generate(11, (i) => 'Permit $i')
    ]) {
      await expectLater(
          service.save(userId: 'u', registration: 'CAR', dates: {
            'custom_expiries': {
              for (var i = 0; i < names.length; i++)
                '$i': {'name': names[i], 'expiry_date': '2099-01-01'}
            }
          }),
          throwsA(isA<CarSaveException>()));
    }
  });
}
