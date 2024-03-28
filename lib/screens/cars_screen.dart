import 'package:car_alerts/screens/add_new_car_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/car.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();

}

class _CarsScreenState extends State<CarsScreen>{
  List<Car> cars = [];
  bool isLoading = true;
  // static final String? databaseURL = dotenv.env['FIREBASE_DATABASE_URL'];
  // final DatabaseReference databaseReference = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: databaseURL).ref();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState(){
    super.initState();
    _fetchCars();
  }

  void _fetchCars() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance.collection('cars').doc(currentUserId).collection('user_cars').get();
    List<Car> fetchedCars = querySnapshot.docs.map((doc) => Car.fromMap(doc.data(), doc.id)).toList();
    setState(() {
      cars = fetchedCars;
      isLoading = false;
    });
  } 

  String mapDatabaseKeyToDisplayName(String databaseKey){
    final displayName = databaseKey.replaceAll('_date', '').replaceAll('_', ' ');
    return displayName[0].toUpperCase() + displayName.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cars"),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator(),) :
        ListView.builder(
          itemCount: cars.length,
          itemBuilder:(context, index) {
            return Card(
              child: ExpansionTile(
                title: Text(cars[index].name),
                children: cars[index].items.entries.map((item){
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text('${mapDatabaseKeyToDisplayName(item.key)} :   ${Car.extractDate(item.value)}'),
                  );
                }).toList(),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            Navigator.push(
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