import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_car_store.dart';

bool sameCarData(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && sameCarData(a[k], b[k]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(a.length, (i) => i).every((i) => sameCarData(a[i], b[i]));
  }
  return a == b;
}

enum TransferResult { moved, alreadyPresent }

class TransferConflict implements Exception {
  TransferConflict(this.dates);
  final Map<String, dynamic>? dates;
}

/// The receipt is committed with the dates in account settings. A retry after process death can
/// finish local cleanup without writing over later account edits.
class LocalCarTransfer {
  LocalCarTransfer(
      {required this.local,
      required this.firestore,
      required this.currentUser});
  final LocalCarStore local;
  final FirebaseFirestore firestore;
  final String? Function() currentUser;
  bool busy = false;
  Future<TransferResult> move(String account,
      {Map<String, dynamic>? expected, bool keepAccount = false}) async {
    if (busy) throw StateError('Transfer already running');
    busy = true;
    final token = local.token;
    final name = local.registration;
    final dates = local.dates;
    try {
      if (token == null || name == null || dates == null) {
        throw StateError('No local car');
      }
      void checkOwner() {
        if (currentUser() != account || local.token != token) {
          throw StateError('Transfer context changed');
        }
      }

      checkOwner();
      final ref = firestore
          .collection('cars')
          .doc(account)
          .collection('user_cars')
          .doc(name);
      final settings = firestore
          .collection('users')
          .doc(account)
          .collection('settings')
          .doc('user_settings');
      final result = await firestore.runTransaction((transaction) async {
        checkOwner();
        final receiptSnapshot = await transaction.get(settings);
        final snapshot = await transaction.get(ref);
        checkOwner();
        final current = snapshot.data();
        final receipts = receiptSnapshot.data()?['_localTransfers'];
        final identical = sameCarData(current, dates);
        if (receipts is Map && receipts[token] == true) {
          return identical
              ? TransferResult.alreadyPresent
              : TransferResult.moved;
        }
        if (!identical && !sameCarData(current, expected)) {
          throw TransferConflict(current);
        }
        if (keepAccount && current == null) throw TransferConflict(null);
        if (!keepAccount && !identical) transaction.set(ref, dates);
        transaction.set(
            settings,
            {
              '_localTransfers': {token: true},
            },
            SetOptions(merge: true));
        return identical ? TransferResult.alreadyPresent : TransferResult.moved;
      });
      checkOwner();
      await local.delete(expectedToken: token);
      return result;
    } finally {
      busy = false;
    }
  }
}
