import 'package:intl/intl.dart';

class Car {
  String name;
  Map<String, String> items;

  final Map<String, Map<String, String>> customExpiries;

  Car(
      {required this.name,
      this.items = const {},
      this.customExpiries = const {}});

  Map<String, String> get allItems => {
        ...items,
        for (final entry in customExpiries.entries)
          'custom:${entry.key}': entry.value['expiry_date']!,
      };

  String itemLabel(String key) {
    if (key.startsWith('custom:')) {
      return customExpiries[key.substring(7)]?['name'] ?? 'Expiry';
    }
    final label = key.replaceAll('_date', '').replaceAll('_', ' ');
    return label.isEmpty
        ? 'Document'
        : '${label[0].toUpperCase()}${label.substring(1)}';
  }

  factory Car.fromMap(Map<String, dynamic> data, String carName) {
    Map<String, String> items = {};
    data.forEach((key, value) {
      if (value is String) {
        items[key] = value;
      }
    });
    final custom = <String, Map<String, String>>{};
    final raw = data['custom_expiries'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is Map &&
            value['name'] is String &&
            value['expiry_date'] is String) {
          custom[entry.key.toString()] = {
            'name': value['name'] as String,
            'expiry_date': value['expiry_date'] as String,
          };
        }
      }
    }
    return Car(name: carName, items: items, customExpiries: custom);
  }

  List<MapEntry<String, int>> getUrgentItems() {
    var now = DateTime.now();
    var urgentItems = allItems.entries.map((e) {
      var expiringDate = DateTime.parse(e.value);
      var difference = expiringDate.difference(now).inDays;
      return MapEntry(_formatItemKey(e.key, e.value), difference);
    }).toList();

    return urgentItems;
  }

  static String extractDate(String firebaseItemDateTime) {
    DateFormat dateFormat = DateFormat("dd MMM yyyy");
    try {
      return dateFormat
          .format(DateTime.parse(firebaseItemDateTime.split('T')[0]));
    } catch (error) {
      return "Invalid Date";
    }
  }

  String _formatItemKey(String key, String value) {
    return "$name ${itemLabel(key)} on ${extractDate(value)}";
  }
}
