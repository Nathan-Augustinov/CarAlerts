import 'package:car_alerts/services/notifications_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/car.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String currentUserName = FirebaseAuth.instance.currentUser!.displayName!;
  final NotificationsService _notificationService = NotificationsService();
  bool isLoading = true;
  List<Car> myCarList = [];
  List<MapEntry<String, int>> urgentItems = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchCars();
    _tabController = TabController(length: 2, vsync: this);
    // showNotificationPermissionsDialog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // void showNotificationPermissionsDialog() async {
  //   //TODO: Implement logic to see if the user has chosen to disable notifications
  //   final userSettingsDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).collection('settings').doc('user_settings').get();
  //   if(userSettingsDoc['notifications'] == false){
  //     _notificationService.requestAndStoreInDatabaseNotificationPermission(FirebaseAuth.instance.currentUser!);
  //   }
  // }

  void _fetchCars() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('cars')
              .doc(currentUserId)
              .collection('user_cars')
              .get();
      List<Car> fetchedCars = querySnapshot.docs
          .map((doc) => Car.fromMap(doc.data(), doc.id))
          .toList();
      setState(() {
        myCarList = fetchedCars;
        urgentItems = myCarList.expand((car) => car.getUrgentItems()).toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching cars: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, int>> expiredItems =
        urgentItems.where((item) => item.value < 0).toList();
    List<MapEntry<String, int>> soonToExpireItems =
        urgentItems.where((item) => item.value >= 0).toList();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          title: Text("Hello, $currentUserName!"),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Already expired"),
              Tab(text: "Soon to expire"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(controller: _tabController, children: [
                _buildItemList(expiredItems, "Already expired"),
                _buildItemList(soonToExpireItems, "Soon to expire")
              ]));
  }

  Widget _buildItemList(List<MapEntry<String, int>> items, String category) {
    return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          var item = items[index];
          Color textColor = item.value > 30
              ? Colors.green
              : item.value > 15
                  ? Colors.orange
                  : Colors.red;
          return ListTile(
            title: Text(item.key, style: TextStyle(color: textColor)),
            subtitle: Text(
                "$category ${item.value > 0 ? "in " : ""}${item.value.abs()} days ${item.value > 0 ? "" : "ago"}",),
          );
        });
  }
}
