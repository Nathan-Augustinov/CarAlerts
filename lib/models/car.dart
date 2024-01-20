class Car{
  String name;
  Map<String, String> items;

  Car({required this.name, this.items = const {}});

  factory Car.fromMap(Map<String, dynamic> data){
    Map<String, String> items = {};
    data.forEach((key, value) {
      if(key != "car_name"){
        items[key] = value as String;
      }
    });
    return Car(name: data['car_name'] as String, items: items);
  }
}