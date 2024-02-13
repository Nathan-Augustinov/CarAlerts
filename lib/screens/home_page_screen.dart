import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/car.dart';
import 'sign_in_screen.dart';
import '../services/authentication.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final String? databaseURL = dotenv.env['FIREBASE_DATABASE_URL'];
  final DatabaseReference databaseReference = FirebaseDatabase.instanceFor(
          app: Firebase.app(), databaseURL: databaseURL)
      .ref();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = true;
  List<Car> myCarList = [];
  List<MapEntry<String, int>> urgentItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  void _signOut(BuildContext context) async {
    await AuthenticationService().signOutFromGoogle();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    }
  }

  void _fetchCars() async {
    DatabaseEvent event =
        await databaseReference.child('cars/$currentUserId').once();
    List<Car> fetchedCars = [];
    if (event.snapshot.exists && event.snapshot.value is Map) {
      Map<dynamic, dynamic> carsData =
          event.snapshot.value as Map<dynamic, dynamic>;
      carsData.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          Map<String, dynamic> carMap = Map.from(value);
          fetchedCars.add(Car.fromMap(carMap));
        }
      });
    }
    setState(() {
      myCarList = fetchedCars;
      urgentItems = myCarList.expand((car) => car.getUrgentItems()).toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, int>> expiredItems = urgentItems.where((item) => item.value < 0).toList();
    List<MapEntry<String, int>> soonToExpireItems = urgentItems.where((item) => item.value >= 0).toList();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          title: const Text("Home Page"),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _signOut(context),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if(expiredItems.isNotEmpty) ...[
                   Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Already expired",
                            style: Theme.of(context).textTheme.titleLarge,
                          ))),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: expiredItems.length,
                        itemBuilder: (context, index) {
                          var item = expiredItems[index];
                          return ListTile(
                            title: Text(item.key,style: const TextStyle(color: Colors.red)),
                            subtitle: Text("Expired ${item.value.abs()} days ago"),
                          );
                        }),
                  )],
                  if(soonToExpireItems.isNotEmpty) ...[
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Soon to expire",
                            style: Theme.of(context).textTheme.titleLarge,
                          ))),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: soonToExpireItems.length,
                        itemBuilder: (context, index) {
                          var item = soonToExpireItems[index];
                          Color textColor = item.value > 30 ? Colors.green : item.value > 15 ? Colors.orange : Colors.red;
                          return ListTile(
                            title: Text(item.key,style: TextStyle(color: textColor)),
                            subtitle: item.value > 30 ? const Text("Expiring in over 30 days") : Text("Expiring in ${item.value} days"),
                          );
                        }),
                  )]
                ],
              ));
  }
}
