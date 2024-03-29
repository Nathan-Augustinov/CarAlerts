import 'package:car_alerts/constants/app_colors.dart';
import 'package:car_alerts/screens/sign_in_screen.dart';
import 'package:car_alerts/services/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userEmail = FirebaseAuth.instance.currentUser!.email!;
  bool darkModeEnabled = false;
  bool notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                  labelText: userEmail,
                  icon: const Icon(Icons.account_circle),
                  border: InputBorder.none),
              enabled: false,
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Theme'),
            value: darkModeEnabled,
            activeColor: Theme.of(context).colorScheme.secondary,
            onChanged: (value) {
              setState(() {
                if (value) {
                  // Enable dark theme
                  // You can use a theme provider or set the theme manually
                  // Example: Provider.of<ThemeProvider>(context, listen: false).setTheme(darkTheme);
                } else {
                  // Enable light theme
                  // Example: Provider.of<ThemeProvider>(context, listen: false).setTheme(lightTheme);
                }
              });
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value:
                notificationsEnabled, // Replace with your logic for notifications
            activeColor: AppColors.firstColor,
            onChanged: (value) {
              setState(() {
                // Update the value for notifications
                // Example: Provider.of<NotificationProvider>(context, listen: false).setNotifications(value);
              });
            },
          ),
          const SizedBox(height: 24),
          TextButton(
              child: Text(
                "Suggest an improvement",
                style: TextStyle(color: AppColors.secondColor, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              onPressed: () {
                // Open a dialog to suggest an improvement
                // Example: showDialog(context: context, builder: (context) => SuggestImprovementDialog());
              }),
          TextButton(
            child: Text(
              "Log out",
              style: TextStyle(color: AppColors.secondColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            onPressed: () {
              _signOut(context);
            },
          ),
        ],
      ),
    );
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
}
