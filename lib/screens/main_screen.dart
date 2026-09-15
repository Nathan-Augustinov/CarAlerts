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

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _tabOptions = <Widget>[
    const MyHomePage(),
    const CarsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
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
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E7EA))),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: 76,
            indicatorColor: const Color(0xFFDDEEEA),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: selected
                    ? const Color(0xFF15766D)
                    : const Color(0xFF647681),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              );
            }),
            iconTheme:
                WidgetStateProperty.resolveWith((states) => IconThemeData(
                      color: states.contains(WidgetState.selected)
                          ? const Color(0xFF15766D)
                          : const Color(0xFF647681),
                      size: 24,
                    )),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.directions_car_outlined),
                selectedIcon: Icon(Icons.directions_car_rounded),
                label: 'Your cars',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
