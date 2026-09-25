import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSettingsService {
  UserSettingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  Future<void> initializeUserSettings(User user) => initializeForUser(user.uid);

  /// Backfill defaults without overwriting another device's saved preferences.
  Future<void> initializeForUser(String uid) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('user_settings');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      final defaults = <String, dynamic>{
        if (!snapshot.exists) 'darkMode': false,
        if (data?['language'] == null) 'language': 'en',
      };
      if (defaults.isNotEmpty) {
        if (snapshot.exists) {
          transaction.update(ref, defaults);
        } else {
          transaction.set(ref, defaults);
        }
      }
    });
  }
}
