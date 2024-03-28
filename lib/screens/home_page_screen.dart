import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/car.dart';
import 'sign_in_screen.dart';
import '../services/authentication.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
        .collection('cars')
        .doc(currentUserId)
        .collection('user_cars')
        .get();
    List<Car> fetchedCars = querySnapshot.docs.map((doc) => Car.fromMap(doc.data(), doc.id)).toList();
    setState(() {
      myCarList = fetchedCars;
      urgentItems = myCarList.expand((car) => car.getUrgentItems()).toList()..sort((a, b) => a.value.compareTo(b.value));
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
