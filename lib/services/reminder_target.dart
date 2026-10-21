import 'dart:convert';
import '../models/car.dart';

class ReminderOwnerMismatch implements Exception {}

/// Check ownership both before fetching and after an asynchronous fetch. The
/// device identity follows the same rule as account identities.
Future<Car?> reminderTarget(
  String? payload, {
  required String? Function() currentOwner,
  required Future<Map<String, Map<String, dynamic>>> Function(String) read,
}) async {
  final data = jsonDecode(payload ?? '') as Map;
  final owner = currentOwner();
  if (owner == null || data['user'] != owner) throw ReminderOwnerMismatch();
  final name = data['car'] as String;
  final cars = await read(owner);
  if (currentOwner() != owner) throw ReminderOwnerMismatch();
  return cars[name] == null ? null : Car.fromMap(cars[name]!, name);
}
