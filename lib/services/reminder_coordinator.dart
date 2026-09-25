import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import '../l10n/localized_content.dart';
import 'dart:convert';
import '../models/car.dart';
import 'package:timezone/timezone.dart' as tz;

const expiryLabels = {
  'insurance_date': 'Insurance',
  'inspection_date': 'Inspection',
  'romanian_vignette_date': 'Romanian vignette',
  'hungarian_vignette_date': 'Hungarian vignette',
  'austrian_vignette_date': 'Austrian vignette',
};

enum ReminderStatus { ready, disabled, failed }

class Reminder {
  final String user, car, category;
  final String? label;
  final String language;
  final int advance;
  final tz.TZDateTime date;
  Reminder(this.user, this.car, this.category, this.advance, this.date,
      {this.label, this.language = 'en'});
  String get key => jsonEncode([user, car, category, advance]);
  String get occurrenceKey => jsonEncode([
        user,
        car,
        category,
        DateTime(date.year, date.month, date.day + advance)
            .toIso8601String()
            .split('T')
            .first
      ]);
  AppLocalizations get localizations =>
      lookupAppLocalizations(Locale(language));
  String get title =>
      '$car · ${label ?? (language == 'en' ? expiryLabels[category] : documentLabel(localizations, category))}';
  String get body => advance == 1
      ? localizations.expiresTomorrow
      : localizations.expiresInDays(advance);
  String get payload => jsonEncode({
        'v': 1,
        'user': user,
        'car': car,
        'key': key,
        'time': date.millisecondsSinceEpoch,
        'zone': date.location.name,
        'title': title,
        'language': language
      });
}

List<Reminder> planReminders(String user,
    Map<String, Map<String, dynamic>> cars, tz.Location zone, DateTime now,
    {int? limit, String language = 'en'}) {
  final result = <Reminder>[];
  for (final car in cars.entries) {
    final model = Car.fromMap(car.value, car.key);
    for (final category in model.allItems.keys) {
      final value = model.allItems[category];
      if (value == null) continue;
      // Stored expiry values represent calendar dates, never UTC instants.
      final date = DateTime.tryParse(value.split('T').first);
      if (date == null) continue;
      for (final advance in [30, 7, 1]) {
        final delivery =
            tz.TZDateTime(zone, date.year, date.month, date.day - advance, 9);
        if (delivery.isAfter(now)) {
          result.add(Reminder(user, car.key, category, advance, delivery,
              language: language,
              label: category.startsWith('custom:')
                  ? model.itemLabel(category)
                  : null));
        }
      }
    }
  }
  result.sort((a, b) {
    final order = a.date.compareTo(b.date);
    return order == 0 ? a.key.compareTo(b.key) : order;
  });
  return limit == null ? result : result.take(limit).toList();
}

/// Only late saves create catch-up work; ordinary refreshes never invent it.
List<Reminder> lateReminders(String user, String car,
    Map<String, dynamic> dates, tz.Location zone, DateTime now,
    {String language = 'en'}) {
  final localNow = tz.TZDateTime.from(now, zone);
  final tomorrow = DateTime(localNow.year, localNow.month, localNow.day + 1);
  final result = <Reminder>[];
  final model = Car.fromMap(dates, car);
  for (final category in model.allItems.keys) {
    final value = model.allItems[category];
    if (value == null) continue;
    final expiry = DateTime.tryParse(value.split('T').first);
    if (expiry == null) continue;
    final delivery =
        tz.TZDateTime(zone, expiry.year, expiry.month, expiry.day - 1, 9);
    if (expiry == tomorrow && !delivery.isAfter(now)) {
      result.add(Reminder(user, car, category, 1, delivery,
          language: language,
          label: category.startsWith('custom:')
              ? model.itemLabel(category)
              : null));
    }
  }
  return result;
}

abstract class ReminderBackend {
  String get language => 'en';
  String? get user;
  int? get limit;
  Future<void> initialize();
  Future<bool> enabled();
  Future<tz.Location> timezone();
  Future<Map<String, Map<String, dynamic>>> cars(String user);
  Future<Map<int, String?>> pending();
  Future<Map<String, int>> loadIds();
  Future<void> saveIds(Map<String, int> ids);
  Future<Map<String, String>> loadHistory();
  Future<void> saveHistory(Map<String, String> history);
  Future<void> show(int id, Reminder reminder);
  Future<void> cancel(int id);
  Future<void> schedule(int id, Reminder reminder);
}

/// The persisted registry is written before scheduling. IDs are never reused,
/// including after delivery/deletion, so collisions cannot overwrite reminders.
class ReminderCoordinator {
  final ReminderBackend backend;
  final DateTime Function() now;
  Future<void> _tail = Future.value();
  ReminderCoordinator(this.backend, {DateTime Function()? now})
      : now = now ?? DateTime.now;

  /// Runs account cleanup after any in-flight scheduling and before the next
  /// refresh, so a stale scheduling operation cannot recreate deleted alerts.
  Future<T> exclusive<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<ReminderStatus> refresh(
      {String? savedUser,
      String? savedCar,
      String? renamedFrom,
      Map<String, dynamic>? savedDates}) {
    final result = _tail
        .then((_) => _refresh(savedUser, savedCar, renamedFrom, savedDates));
    _tail = result.then((_) {});
    return result;
  }

  Future<ReminderStatus> _refresh(String? savedUser, String? savedCar,
      String? renamedFrom, Map<String, dynamic>? savedDates) async {
    try {
      await backend.initialize();
      final user = backend.user;
      final pending = await backend.pending();
      // Account isolation precedes fetching: a failed fetch must not leave
      // another user's private reminders on this device.
      for (final entry in pending.entries.toList()) {
        String? owner;
        try {
          owner = (jsonDecode(entry.value ?? '') as Map)['user'] as String?;
        } catch (_) {}
        if (user == null || (owner != null && owner != user)) {
          await backend.cancel(entry.key);
          pending.remove(entry.key);
        }
      }
      final history = await backend.loadHistory();
      history.removeWhere((key, state) =>
          state == 'queued' && (jsonDecode(key) as List).first != user);
      if (user == null) {
        await backend.saveHistory(history);
        return ReminderStatus.ready;
      }
      if (savedUser == user &&
          savedCar != null &&
          renamedFrom != null &&
          renamedFrom != savedCar) {
        // A rename is the same car: preserve catch-up deduplication so editing
        // its registration cannot replay a reminder that has already fired.
        for (final entry in history.entries.toList()) {
          final key = jsonDecode(entry.key) as List;
          if (key[0] == user && key[1] == renamedFrom) {
            key[1] = savedCar;
            final renamedKey = jsonEncode(key);
            if (history[renamedKey] == null ||
                history[renamedKey] == 'queued') {
              history[renamedKey] = entry.value;
            }
            history.remove(entry.key);
          }
        }
      }
      final zone = await backend.timezone();
      if (savedUser == user && savedCar != null && savedDates != null) {
        for (final reminder in lateReminders(
            user, savedCar, savedDates, zone, now(),
            language: backend.language)) {
          history.putIfAbsent(reminder.occurrenceKey, () => 'queued');
        }
      }
      // Persist intent before permission checks/fetches so failures can retry.
      await backend.saveHistory(history);
      final enabled = await backend.enabled();
      if (!enabled) {
        for (final id in pending.keys) {
          await backend.cancel(id);
        }
        return ReminderStatus.disabled;
      }
      final cars = await backend.cars(user);
      if (backend.user != user) return ReminderStatus.ready;
      final desired = planReminders(user, cars, zone, now(),
          limit: backend.limit, language: backend.language);
      final late = <Reminder>[];
      for (final car in cars.entries) {
        late.addAll(lateReminders(user, car.key, car.value, zone, now(),
                language: backend.language)
            .where((r) => history[r.occurrenceKey] == 'queued'));
      }
      final eligible = late.map((r) => r.occurrenceKey).toSet();
      history.removeWhere(
          (key, state) => state == 'queued' && !eligible.contains(key));
      await backend.saveHistory(history);
      final ids = await backend.loadIds();
      final occupied = {...ids.values, ...pending.keys};
      var next = occupied.fold<int>(0, (a, b) => a > b ? a : b) + 1;
      for (final reminder in [...desired, ...late]) {
        if (!ids.containsKey(reminder.key)) {
          if (next > 2147483647) throw StateError('Notification IDs exhausted');
          ids[reminder.key] = next++;
        }
      }
      await backend.saveIds(ids);
      final wanted = {for (final r in desired) ids[r.key]!: r};
      for (final entry in pending.entries) {
        if (backend.user != user) return ReminderStatus.ready;
        if (!wanted.containsKey(entry.key)) await backend.cancel(entry.key);
      }
      for (final entry in wanted.entries) {
        if (backend.user != user) return ReminderStatus.ready;
        if (pending[entry.key] != entry.value.payload) {
          await backend.schedule(entry.key, entry.value);
          // An auth change can occur while the native schedule call is running.
          if (backend.user != user) await backend.cancel(entry.key);
        }
        if (entry.value.advance == 1 && backend.user == user) {
          history[entry.value.occurrenceKey] = 'scheduled';
          await backend.saveHistory(history);
        }
      }
      for (final reminder in late) {
        if (backend.user != user) return ReminderStatus.ready;
        // A slow fetch/scheduling batch can cross midnight.
        if (!lateReminders(user, reminder.car, cars[reminder.car]!, zone, now())
            .any((r) => r.occurrenceKey == reminder.occurrenceKey)) {
          history.remove(reminder.occurrenceKey);
          await backend.saveHistory(history);
          continue;
        }
        // Write ahead to avoid replay after process death between showing an
        // alert and recording it. A reported native failure remains retryable.
        history[reminder.occurrenceKey] = 'shown';
        await backend.saveHistory(history);
        try {
          await backend.show(ids[reminder.key]!, reminder);
        } catch (_) {
          history[reminder.occurrenceKey] = 'queued';
          await backend.saveHistory(history);
          rethrow;
        }
        if (backend.user != user) await backend.cancel(ids[reminder.key]!);
      }
      return ReminderStatus.ready;
    } catch (_) {
      // No success marker: the next refresh retries partial work.
      return ReminderStatus.failed;
    }
  }
}
