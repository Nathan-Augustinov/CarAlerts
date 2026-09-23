import 'dart:async';
import 'package:car_alerts/services/account_deletion_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

class DeletingUser extends MockUser {
  DeletingUser() : super(uid: 'a', email: 'test@example.com');
  bool deleted = false;
  bool failDelete = false;
  Future<void> Function()? beforeDelete;
  @override
  Future<void> delete() async {
    if (failDelete) throw FirebaseAuthException(code: 'network-request-failed');
    await beforeDelete?.call();
    deleted = true;
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late DeletingUser user;
  late MockFirebaseAuth auth;
  late List<String> steps;
  late bool failReauthentication;
  late bool failReminders;

  AccountDeletionService service() => AccountDeletionService(
        auth: auth,
        firestore: db,
        reauthenticate: (currentUser, password) async {
          steps.add('verify');
          expect(currentUser.uid, 'a');
          if (failReauthentication)
            throw FirebaseAuthException(code: 'wrong-password');
        },
        withoutReminders: (uid, action) async {
          steps.add('reminders');
          expect(uid, 'a');
          if (failReminders) throw StateError('Native cleanup failed');
          await action();
        },
        clearGoogleSession: () async {},
      );

  setUp(() async {
    db = FakeFirebaseFirestore();
    user = DeletingUser();
    auth = MockFirebaseAuth(mockUser: user, signedIn: true);
    steps = [];
    failReauthentication = false;
    failReminders = false;
    await db.doc('cars/a/user_cars/CAR').set({'insurance_date': '2027-01-01'});
    await db.doc('users/a/settings/user_settings').set({'darkMode': false});
    await db.doc('users/a').set({'name': 'Test'});
    await db.doc('cars/a').set({'metadata': 'test'});
    await db
        .doc('cars/b/user_cars/OTHER')
        .set({'insurance_date': '2028-01-01'});
  });

  test('data and reminders are removed before identity, other users remain',
      () async {
    user.beforeDelete = () async {
      steps.add('identity');
      expect((await db.collection('cars/a/user_cars').get()).docs, isEmpty);
      expect((await db.collection('users/a/settings').get()).docs, isEmpty);
      expect((await db.doc('users/a').get()).exists, isFalse);
      expect((await db.doc('cars/a').get()).exists, isFalse);
    };
    await service().delete(password: 'verified');
    expect(steps, ['verify', 'reminders', 'identity']);
    expect(user.deleted, isTrue);
    expect((await db.doc('cars/b/user_cars/OTHER').get()).exists, isTrue);
  });

  test('failed verification leaves all data and reminders untouched', () async {
    failReauthentication = true;
    await expectLater(service().delete(password: 'wrong'),
        throwsA(isA<FirebaseAuthException>()));
    expect(steps, ['verify']);
    expect(user.deleted, isFalse);
    expect((await db.doc('cars/a/user_cars/CAR').get()).exists, isTrue);
    expect(
        (await db.doc('users/a/settings/user_settings').get()).exists, isTrue);
  });

  test('failed reminder cleanup does not delete cloud data or identity',
      () async {
    failReminders = true;
    await expectLater(service().delete(password: 'verified'), throwsStateError);
    expect(user.deleted, isFalse);
    expect((await db.doc('cars/a/user_cars/CAR').get()).exists, isTrue);
  });

  test('failed cloud cleanup retains account and reports incomplete deletion',
      () async {
    db.securityRules = FakeFirebaseFirestore(securityRules: '''
      service cloud.firestore {
        match /databases/{database}/documents {
          match /{document=**} { allow read: if true; allow write: if false; }
        }
      }
    ''').securityRules;
    await expectLater(service().delete(password: 'verified'),
        throwsA(isA<AccountDeletionException>()));
    expect(user.deleted, isFalse);
    expect((await db.doc('cars/a/user_cars/CAR').get()).exists, isTrue);
  });

  test('identity failure can be retried after data cleanup', () async {
    user.failDelete = true;
    final deletion = service();
    await expectLater(deletion.delete(password: 'verified'),
        throwsA(isA<AccountDeletionException>()));
    expect(user.deleted, isFalse);
    expect((await db.collection('cars/a/user_cars').get()).docs, isEmpty);
    user.failDelete = false;
    await deletion.delete(password: 'verified');
    expect(user.deleted, isTrue);
  });

  test('more than one deletion batch is fully cleaned', () async {
    final batch = db.batch();
    for (var index = 0; index < 405; index++) {
      batch.set(db.doc('cars/a/user_cars/CAR$index'),
          {'insurance_date': '2027-01-01'});
    }
    await batch.commit();
    await service().delete(password: 'verified');
    expect((await db.collection('cars/a/user_cars').get()).docs, isEmpty);
    expect(user.deleted, isTrue);
  });

  test('signing out during verification stops deletion', () async {
    final deletion = AccountDeletionService(
      auth: auth,
      firestore: db,
      reauthenticate: (_, __) async => auth.signOut(),
      withoutReminders: (_, __) async => fail('Cleanup must not start'),
      clearGoogleSession: () async {},
    );
    await expectLater(deletion.delete(), throwsA(isA<FirebaseAuthException>()));
    expect(user.deleted, isFalse);
    expect((await db.doc('cars/a/user_cars/CAR').get()).exists, isTrue);
  });

  test('double submission cannot start a second deletion', () async {
    final gate = Completer<void>();
    final deletion = AccountDeletionService(
      auth: auth,
      firestore: db,
      reauthenticate: (_, __) => gate.future,
      withoutReminders: (_, action) => action(),
      clearGoogleSession: () async {},
    );
    final first = deletion.delete();
    await expectLater(deletion.delete(), throwsStateError);
    gate.complete();
    await first;
    expect(user.deleted, isTrue);
  });
}
