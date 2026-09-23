import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    try {
      await _reauthenticate(user, password);
      _checkUser(user.uid);
      await _withoutReminders(user.uid, () async {
        _checkUser(user.uid);
        cleanupStarted = true;
        // Delete the known subcollections explicitly; deleting their parent
        // documents alone would leave all the user's cars/settings behind.
        final cars = _firestore.collection('cars').doc(user.uid);
        final profile = _firestore.collection('users').doc(user.uid);
        await _deleteCollection(cars.collection('user_cars'), user.uid);
        await _deleteCollection(profile.collection('settings'), user.uid);
        _checkUser(user.uid);
        final parents = _firestore.batch();
        parents.delete(cars);
        parents.delete(profile);
        await parents.commit();
        _checkUser(user.uid);
        // Keep authentication until data cleanup succeeds so a failure remains
        // retryable under the same user's security rules.
        await user.delete();
      });
      if (user.providerData
          .any((provider) => provider.providerId == 'google.com')) {
        try {
          await _clearGoogleSession();
        } catch (_) {
          // The Firebase account is already deleted; provider cache cleanup
          // must not present a successfully deleted account as a failure.
        }
      }
    } catch (_) {
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
