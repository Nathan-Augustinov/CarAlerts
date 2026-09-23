import 'package:cloud_firestore/cloud_firestore.dart';

class CarSaveException implements Exception {
  const CarSaveException(this.message);
  final String message;
}

class CarService {
  CarService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  Future<void> save({
    required String userId,
    required String registration,
    required Map<String, dynamic> dates,
    String? previousRegistration,
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
    await _firestore.runTransaction((transaction) async {
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
      transaction.set(destination, {...existing, ...dates});
      if (previousRegistration != null && previousRegistration != name) {
        transaction.delete(cars.doc(previousRegistration));
      }
    });
  }
}
