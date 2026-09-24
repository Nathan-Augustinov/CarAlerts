import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car.dart';
import '../models/expiry_validation.dart';

class CarSaveException implements Exception {
  const CarSaveException(this.message);
  final String message;
}

class CarService {
  CarService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>> save({
    required String userId,
    required String registration,
    required Map<String, dynamic> dates,
    String? previousRegistration,
    Map<String, dynamic>? originalDates,
  }) async {
    final name = registration.trim();
    if (name.isEmpty || name.contains('/') || name == '.' || name == '..') {
      throw const CarSaveException('Enter a valid registration number.');
    }
    final cars =
        _firestore.collection('cars').doc(userId).collection('user_cars');
    final destination = cars.doc(name);
    // Checking and writing in the same transaction also protects against
    // another device creating the destination while this form is open.
    return _firestore.runTransaction((transaction) async {
      final target = await transaction.get(destination);
      if (previousRegistration != name && target.exists) {
        throw const CarSaveException(
            'You already have a car with this registration number.');
      }
      Map<String, dynamic> existing = target.data() ?? {};
      if (previousRegistration != null) {
        final original = previousRegistration == name
            ? target
            : await transaction.get(cars.doc(previousRegistration));
        if (!original.exists) {
          throw const CarSaveException(
              'This car has been removed or renamed. Reopen it from Your cars.');
        }
        existing = original.data()!;
      }
      final updated = originalDates == null
          ? {...existing, ...dates}
          : _applyChanges(existing, originalDates, dates);
      final custom = updated['custom_expiries'];
      if (custom is Map) {
        if (custom.length > 10) {
          throw const CarSaveException(
              'Add at most 10 custom expiries per car.');
        }
        final names = <String>{};
        for (final value in custom.values) {
          if (value is! Map ||
              value['name'] is! String ||
              value['expiry_date'] is! String) {
            throw const CarSaveException(
                'Enter a name and date for each custom expiry.');
          }
          final name = (value['name'] as String).trim();
          if (name.isEmpty ||
              name.length > 50 ||
              !names.add(name.toLowerCase())) {
            throw const CarSaveException(
                'Use unique expiry names of 1–50 characters.');
          }
        }
      }
      final original = Car.fromMap(existing, name).allItems;
      for (final entry in Car.fromMap(updated, name).allItems.entries) {
        if (entry.value == original[entry.key]) continue;
        final error = validateExpiryDate(DateTime.tryParse(entry.value),
            original: original[entry.key]);
        if (error != null) throw CarSaveException(error);
      }
      transaction.set(destination, updated);
      if (previousRegistration != null && previousRegistration != name) {
        transaction.delete(cars.doc(previousRegistration));
      }
      return updated;
    });
  }
}

/// Apply only the editor's changes to the latest transaction snapshot.
/// Recurse into custom expiries so independent entries and fields survive.
Map<String, dynamic> _applyChanges(Map<String, dynamic> latest,
    Map<String, dynamic> original, Map<String, dynamic> edited) {
  final result = Map<String, dynamic>.from(latest);
  for (final key in {...original.keys, ...edited.keys}) {
    final before = original[key];
    final after = edited[key];
    if (before is Map && after is Map) {
      result[key] = _applyChanges(
          latest[key] is Map
              ? Map<String, dynamic>.from(latest[key] as Map)
              : {},
          Map<String, dynamic>.from(before),
          Map<String, dynamic>.from(after));
      // An unchanged entry deleted on another device must stay deleted.
      if (!latest.containsKey(key) && (result[key] as Map).isEmpty) {
        result.remove(key);
      }
    } else if (before != after) {
      if (edited.containsKey(key)) {
        result[key] = after;
      } else {
        result.remove(key);
      }
    }
  }
  return result;
}
