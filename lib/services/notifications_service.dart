import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;
import 'notification_permission_service.dart';
import 'reminder_coordinator.dart';

export 'reminder_coordinator.dart' show ReminderStatus;

class NotificationsService extends ReminderBackend {
  static final instance = NotificationsService();
  static const _channel = MethodChannel('car_alerts/notification_permissions');
  final _plugin = FlutterLocalNotificationsPlugin();
  late final coordinator = ReminderCoordinator(this);
  Future<void>? _initialization;
  void Function(String?)? onTap;
  String? launchPayload;
  Timer? _retry;
  bool _deletingAccount = false;
  Future<ReminderStatus> refresh(
      {String? savedUser,
      String? savedCar,
      String? renamedFrom,
      Map<String, dynamic>? savedDates}) async {
    if (_deletingAccount) return ReminderStatus.ready;
    final status = await coordinator.refresh(
        savedUser: savedUser,
        savedCar: savedCar,
        renamedFrom: renamedFrom,
        savedDates: savedDates);
    _retry?.cancel();
    if (status == ReminderStatus.failed && !_deletingAccount) {
      _retry = Timer(
          const Duration(minutes: 1),
          () => refresh(
              savedUser: savedUser,
              savedCar: savedCar,
              renamedFrom: renamedFrom,
              savedDates: savedDates));
    }
    return status;
  }

  Future<void> withoutAccountReminders(
      String account, Future<void> Function() deleteDataAndAccount) async {
    if (_deletingAccount) {
      throw StateError('Account deletion is already running');
    }
    _deletingAccount = true;
    _retry?.cancel();
    try {
      await coordinator.exclusive(() async {
        await initialize();
        final ids = await loadIds();
        final history = await loadHistory();
        bool belongsToAccount(String key) {
          final decoded = jsonDecode(key);
          return decoded is List &&
              decoded.isNotEmpty &&
              decoded.first == account;
        }

        final ownedIds = ids.entries
            .where((entry) => belongsToAccount(entry.key))
            .map((entry) => entry.value)
            .toSet();
        for (final entry in (await pending()).entries) {
          try {
            if ((jsonDecode(entry.value ?? '') as Map)['user'] == account) {
              ownedIds.add(entry.key);
            }
          } catch (_) {
            // Unrelated legacy payloads do not identify this account.
          }
        }
        // Registry IDs include delivered alerts as well as pending reminders.
        for (final id in ownedIds) {
          await cancel(id);
        }
        history.removeWhere((key, _) => belongsToAccount(key));
        await saveHistory(history);
        ids.removeWhere((key, _) => belongsToAccount(key));
        await saveIds(ids);
        await deleteDataAndAccount();
      });
    } finally {
      _deletingAccount = false;
      // Restore remaining reminders after a failed deletion, or reconcile the
      // signed-out state after a successful one.
      unawaited(refresh());
    }
  }

  @override
  String? get user => FirebaseAuth.instance.currentUser?.uid;
  @override
  int? get limit => Platform.isIOS ? 64 : null;
  @override
  Future<void> initialize() async {
    try {
      await (_initialization ??= _initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    data.initializeTimeZones();
    await _plugin.initialize(
        settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
                defaultPresentAlert: true,
                defaultPresentSound: true)),
        onDidReceiveNotificationResponse: (response) =>
            onTap?.call(response.payload));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
            '1', 'Expiry Notifications',
            description: 'Reminders for car expiry dates',
            importance: Importance.high));
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      launchPayload = launch?.notificationResponse?.payload;
    }
  }

  @override
  Future<bool> enabled() async =>
      await NotificationPermissionService().status() ==
      NotificationPermission.enabled;
  @override
  Future<tz.Location> timezone() async =>
      tz.getLocation((await _channel.invokeMethod<String>('timezone'))!);
  @override
  Future<Map<String, Map<String, dynamic>>> cars(String user) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('cars')
        .doc(user)
        .collection('user_cars')
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    return {for (final doc in snapshot.docs) doc.id: doc.data()};
  }

  @override
  Future<Map<int, String?>> pending() async => {
        for (final request in await _plugin.pendingNotificationRequests())
          request.id: request.payload
      };
  @override
  Future<Map<String, int>> loadIds() async => Map<String, int>.from(
      jsonDecode(await _channel.invokeMethod<String>('loadReminderIds') ?? '{}')
          as Map);
  @override
  Future<void> saveIds(Map<String, int> ids) =>
      _channel.invokeMethod('saveReminderIds', jsonEncode(ids));
  @override
  Future<Map<String, String>> loadHistory() async => Map<String, String>.from(
      jsonDecode(await _channel.invokeMethod<String>('loadReminderHistory') ??
          '{}') as Map);
  @override
  Future<void> saveHistory(Map<String, String> history) =>
      _channel.invokeMethod('saveReminderHistory', jsonEncode(history));
  @override
  Future<void> show(int id, Reminder reminder) => _plugin.show(
      id: id,
      title: reminder.title,
      body: reminder.body,
      payload: reminder.payload,
      notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('1', 'Expiry Notifications',
              channelDescription: 'Reminders for car expiry dates',
              importance: Importance.high,
              priority: Priority.high,
              onlyAlertOnce: true),
          iOS: DarwinNotificationDetails(
              presentAlert: true, presentSound: true)));
  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
  @override
  Future<void> schedule(int id, Reminder reminder) => _plugin.zonedSchedule(
      id: id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: reminder.date,
      payload: reminder.payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('1', 'Expiry Notifications',
              channelDescription: 'Reminders for car expiry dates',
              importance: Importance.high),
          iOS: DarwinNotificationDetails(
              presentAlert: true, presentSound: true)));
}
