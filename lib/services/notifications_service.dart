import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Future<void> requestAndStoreInDatabaseNotificationPermission(User user) async {
  //   NotificationSettings settings = await _firebaseMessaging.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );

  //   bool notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
  //   _firestore.collection('users').doc(user.uid).collection('settings').doc('user_settings').update({
  //     'notifications': notificationsEnabled,
  //   });
  // }

  void localNotificationsInitialization(){
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  //TODO: Debugging to see if the notifications are being scheduled
  void scheduleNotification(String itemId, DateTime expiringDate, String title) async {
    final DateTime scheduleNotificationOneWeekBefore = expiringDate.subtract(const Duration(days: 7));
    final DateTime scheduleNotificationThreeDaysBefore = expiringDate.subtract(const Duration(days: 3));
    final DateTime scheduleNotificationOneDayBefore = expiringDate.subtract(const Duration(days: 1));
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      '1',
      'Expiry Notifications',
      channelDescription: 'Notifications for items that are about to expire',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iosDetails);
    
    if(!scheduleNotificationOneWeekBefore.isBefore(DateTime.now())){
      await flutterLocalNotificationsPlugin.zonedSchedule(
        itemId.hashCode, 
        title, 
        'Your car insurance will expire in a week!', 
        tz.TZDateTime.from(scheduleNotificationOneWeekBefore, tz.local),
        platformDetails, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
      );
    }
    
    if(!scheduleNotificationThreeDaysBefore.isBefore(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        itemId.hashCode, 
        title, 
        'Your car inspection will expire in three days!', 
        tz.TZDateTime.from(scheduleNotificationThreeDaysBefore, tz.local),
        platformDetails, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
      );
    }
    
    if(!scheduleNotificationOneDayBefore.isBefore(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        itemId.hashCode, 
        title, 
        'Your car inspection will expire tomorrow!', 
        tz.TZDateTime.from(scheduleNotificationOneDayBefore, tz.local),
        platformDetails, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
      );
    }
  }
}