import 'package:car_alerts/main.dart';
import 'package:car_alerts/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'home_page_screen.dart';
import 'cars_screen.dart';

class MainScreen extends StatefulWidget {
  MainScreen() : super(key: mainScreenKey);

  @override
  State<MainScreen> createState() => MainScreenState();

}

class MainScreenState extends State<MainScreen>{

  int _selectedIndex = 0;

  static final List<Widget> _tabOptions = <Widget>[
    const MyHomePage(),
    const CarsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  void selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _tabOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.car_rental),
            label: 'Your Cars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }


}

