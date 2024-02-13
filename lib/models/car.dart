import 'package:intl/intl.dart';

class Car {
  String name;
  Map<String, String> items;

  Car({required this.name, this.items = const {}});

  factory Car.fromMap(Map<String, dynamic> data) {
    Map<String, String> items = {};
    data.forEach((key, value) {
      if (key != "car_name") {
        items[key] = value as String;
      }
    });
    return Car(name: data['car_name'] as String, items: items);
  }

  List<MapEntry<String, int>> getUrgentItems() {
    var now = DateTime.now();
    var urgentItems = items.entries.map((e) {
      var expiringDate = DateTime.parse(e.value);
      var difference = expiringDate.difference(now).inDays;
      return MapEntry(_formatItemKey(e.key, e.value), difference);
    }).toList();

    return urgentItems;
  }

  static String extractDate(String firebaseItemDateTime){
    DateFormat dateFormat = DateFormat("dd MMM yyyy");
    try{
      return dateFormat.format(DateTime.parse(firebaseItemDateTime.split('T')[0]));
    }
    catch (error){
      return "Invalid Date";
    }
  }

  String _formatItemKey(String key, String value) {
    return "$name ${key.replaceAll('_', ' ').replaceAll('date', '')}on ${extractDate(value)}";
  }
}
