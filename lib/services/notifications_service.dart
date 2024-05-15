import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> requestAndStoreInDatabaseNotificationPermission(User user) async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    bool notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
    _firestore.collection('users').doc(user.uid).collection('settings').doc('user_settings').update({
      'notifications': notificationsEnabled,
    });
  }
}