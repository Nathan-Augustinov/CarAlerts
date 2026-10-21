import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'car_service.dart';
import 'local_car_store.dart';

/// Captures its owner so an editor can never write to a newly selected account.
class CarStore {
  CarStore(this.owner, {FirebaseFirestore? firestore}) : _firestore = firestore;
  factory CarStore.current() =>
      CarStore(FirebaseAuth.instance.currentUser?.uid ?? localOwner);
  final String owner;
  final FirebaseFirestore? _firestore;
  bool get isLocal => owner == localOwner;
  CollectionReference<Map<String, dynamic>> get collection =>
      (_firestore ?? FirebaseFirestore.instance)
          .collection('cars')
          .doc(owner)
          .collection('user_cars');
  Stream<Map<String, Map<String, dynamic>>> watch() => isLocal
      ? LocalCarStore.instance.watch()
      : collection
          .snapshots()
          .map((s) => {for (final d in s.docs) d.id: d.data()});
  Future<Map<String, Map<String, dynamic>>> read() async => isLocal
      ? LocalCarStore.instance.cars
      : {
          for (final d
              in (await collection.get(const GetOptions(source: Source.server)))
                  .docs)
            d.id: d.data()
        };
  Future<void> delete(String registration) async {
    if (isLocal) {
      if (LocalCarStore.instance.registration != registration) {
        throw StateError('Local car changed');
      }
      await LocalCarStore.instance
          .delete(expectedToken: LocalCarStore.instance.token);
    } else {
      await collection.doc(registration).delete();
    }
  }

  Future<Map<String, dynamic>> save(
          {required String registration,
          required Map<String, dynamic> dates,
          String? previousRegistration,
          Map<String, dynamic>? originalDates}) =>
      isLocal
          ? LocalCarStore.instance.save(
              registration: registration,
              dates: dates,
              previousRegistration: previousRegistration,
              originalDates: originalDates)
          : CarService(firestore: _firestore).save(
              userId: owner,
              registration: registration,
              dates: dates,
              previousRegistration: previousRegistration,
              originalDates: originalDates);
}
