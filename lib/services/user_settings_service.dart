import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeUserSettings(User user) async {
    // final settingsRef = _database.ref('users/${user.uid}/settings');
    final settingsRef = _firestore.collection('users').doc(user.uid).collection('settings').doc('user_settings');
    // final userSettings = await settingsRef.once();
    final userSettings = await settingsRef.get();
    if (!userSettings.exists) {
      await settingsRef.set({
        'notifications': false,
        'darkMode': false,
      });
    }
  }
}