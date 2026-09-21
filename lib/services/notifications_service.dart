import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static Future<void>? _initialization;
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin =>
      _plugin;

  Future<void> localNotificationsInitialization() =>
      _initialization ??= _initialize();

  Future<void> _initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings);
    tz.initializeTimeZones();
  }

  //TODO: Debugging to see if the notifications are being scheduled
  Future<void> scheduleNotification(
      String itemId, DateTime expiringDate, String title) async {
    await localNotificationsInitialization();
    final DateTime scheduleNotificationOneWeekBefore =
        expiringDate.subtract(const Duration(days: 7));
    final DateTime scheduleNotificationThreeDaysBefore =
        expiringDate.subtract(const Duration(days: 3));
    final DateTime scheduleNotificationOneDayBefore =
        expiringDate.subtract(const Duration(days: 1));
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      '1',
      'Expiry Notifications',
      channelDescription: 'Notifications for items that are about to expire',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iosDetails);

    if (!scheduleNotificationOneWeekBefore.isBefore(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
          id: itemId.hashCode,
          title: title,
          body: 'Your car insurance will expire in a week!',
          scheduledDate:
              tz.TZDateTime.from(scheduleNotificationOneWeekBefore, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
    }

    if (!scheduleNotificationThreeDaysBefore.isBefore(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
          id: itemId.hashCode,
          title: title,
          body: 'Your car inspection will expire in three days!',
          scheduledDate:
              tz.TZDateTime.from(scheduleNotificationThreeDaysBefore, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
    }

    if (!scheduleNotificationOneDayBefore.isBefore(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
          id: itemId.hashCode,
          title: title,
          body: 'Your car inspection will expire tomorrow!',
          scheduledDate:
              tz.TZDateTime.from(scheduleNotificationOneDayBefore, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
    }
  }
}
