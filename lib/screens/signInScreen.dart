import 'package:car_alerts/screens/mainScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/authentication.dart';

class SignInScreen extends StatelessWidget {
  final AuthenticationService _authService = AuthenticationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await _authService.signInWithGoogle();
            if (user != null) {
              // Navigate to Home Screen
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => MainScreen())
              );
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
