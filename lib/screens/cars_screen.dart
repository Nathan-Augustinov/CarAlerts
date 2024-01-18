import 'package:car_alerts/screens/add_new_car_screen.dart';
import 'package:flutter/material.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();

}

class _CarsScreenState extends State<CarsScreen>{

  List<String> cars = ["Car1", "Car2", "Car3"];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cars"),
      ),
      body: ListView.builder(
        itemCount: cars.length,
        itemBuilder:(context, index) {
          return Card(
            child: ExpansionTile(
              title: Text(cars[index]),
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Item 1 : Expiration date"),
                      Text("Item 2 : Expiration date"),
                    ],
                  ),
                )
              ],
            ),
          );
        } 
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) =>  const AddNewCarScreen())
          );
        },
        tooltip: "Add a new car",
        child: const Icon(Icons.add),
      ),
    );
  }
}