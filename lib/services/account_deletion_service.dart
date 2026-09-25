import 'crash_reporting_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'authentication_service.dart';
import 'notifications_service.dart';

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);
  final String message;
}

class AccountDeletionService {
  AccountDeletionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Future<void> Function(User, String?)? reauthenticate,
    Future<void> Function(String, Future<void> Function())? withoutReminders,
    Future<void> Function()? clearGoogleSession,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _reauthenticate =
            reauthenticate ?? AuthenticationService().reauthenticateForDeletion,
        _withoutReminders = withoutReminders ??
            NotificationsService.instance.withoutAccountReminders,
        _clearGoogleSession =
            clearGoogleSession ?? AuthenticationService().clearGoogleSession;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Future<void> Function(User, String?) _reauthenticate;
  final Future<void> Function(String, Future<void> Function())
      _withoutReminders;
  final Future<void> Function() _clearGoogleSession;
  bool _running = false;

  Future<void> delete({String? password}) async {
    if (_running) throw StateError('Account deletion is already running');
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');
    _running = true;
    var cleanupStarted = false;
    var stage = 'verification';
    CrashReportingService.instance.breadcrumb('account: deletion_started');
    try {
      await _reauthenticate(user, password);
      _checkUser(user.uid);
      stage = 'reminder cleanup';
      await _withoutReminders(user.uid, () async {
        _checkUser(user.uid);
        cleanupStarted = true;
        stage = 'settings cleanup';
        // Delete the known subcollections explicitly; deleting their parent
        // documents alone would leave all the user's cars/settings behind.
        final cars = _firestore.collection('cars').doc(user.uid);
        final profile = _firestore.collection('users').doc(user.uid);
        // Settings use one fixed document. Querying the collection requires
        // list permission, which document-specific rules need not grant.
        await profile.collection('settings').doc('user_settings').delete();
        stage = 'cars cleanup';
        await _deleteCollection(cars.collection('user_cars'), user.uid);
        _checkUser(user.uid);
        // These parent paths are containers only: the app stores all data in
        // their subcollections. Deleting nonexistent parents still requires
        // separate Firestore permissions and can block Auth deletion.
        // Keep authentication until data cleanup succeeds so a failure remains
        // retryable under the same user's security rules.
        stage = 'account removal';
        await user.delete();
      });
      if (user.providerData
          .any((provider) => provider.providerId == 'google.com')) {
        try {
          await _clearGoogleSession();
        } catch (error, stack) {
          CrashReportingService.instance
              .report(error, stack, operation: 'clear_google_session');
          // The Firebase account is already deleted; provider cache cleanup
          // must not present a successfully deleted account as a failure.
        }
      }
    } catch (error, stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'delete_account: $stage');
      final code = error is FirebaseException ? error.code : error.runtimeType;
      debugPrint('Account deletion failed during $stage ($code).');
      if (cleanupStarted) {
        throw const AccountDeletionException(
            'Deletion did not finish. Some saved data may already be removed. '
            'Please try again to finish deleting your account.');
      }
      rethrow;
    } finally {
      _running = false;
    }
  }

  void _checkUser(String uid) {
    if (_auth.currentUser?.uid != uid) {
      throw FirebaseAuthException(code: 'user-mismatch');
    }
  }

  Future<void> _deleteCollection(
      CollectionReference<Map<String, dynamic>> collection, String uid) async {
    while (true) {
      _checkUser(uid);
      final snapshot = await collection
          .limit(400)
          .get(const GetOptions(source: Source.server));
      if (snapshot.docs.isEmpty) return;
      _checkUser(uid);
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}
