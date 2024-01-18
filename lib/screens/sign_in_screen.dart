import 'package:car_alerts/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/authentication.dart';

class SignInScreen extends StatelessWidget {
  final AuthenticationService _authService = AuthenticationService();

  SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await _authService.signInWithGoogle();
            if (user != null && context.mounted) {
              // Navigate to Home Screen
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) =>  const MainScreen())
              );
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
