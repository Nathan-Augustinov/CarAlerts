import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
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
    final isRomanian = Localizations.localeOf(context).languageCode == 'ro';
    return Scaffold(
      body: Center(
        child: _tabOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.surface,
          border: Border(top: BorderSide(color: context.palette.border)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: context.palette.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: 76,
            indicatorColor: context.palette.selected,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color:
                    selected ? context.palette.accent : context.palette.muted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              );
            }),
            iconTheme:
                WidgetStateProperty.resolveWith((states) => IconThemeData(
                      color: states.contains(WidgetState.selected)
                          ? context.palette.accent
                          : context.palette.muted,
                      size: 24,
                    )),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(isRomanian
                    ? Icons.home_outlined
                    : Icons.space_dashboard_outlined),
                selectedIcon: Icon(isRomanian
                    ? Icons.home_rounded
                    : Icons.space_dashboard_rounded),
                label: AppLocalizations.of(context)!.dashboard,
              ),
              NavigationDestination(
                icon: const Icon(Icons.directions_car_outlined),
                selectedIcon: const Icon(Icons.directions_car_rounded),
                label: AppLocalizations.of(context)!.yourCars,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: AppLocalizations.of(context)!.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
