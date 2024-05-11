import 'package:car_alerts/constants/app_colors.dart';
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
      // body: Center(
      //   child: ElevatedButton(
      //     onPressed: () async {
      //       User? user = await _authService.signInWithGoogle();
      //       if (user != null && context.mounted) {
      //         // Navigate to Home Screen
      //         Navigator.pushReplacement(
      //           context,
      //           MaterialPageRoute(builder: (context) =>  MainScreen())
      //         );
      //       }
      //     },
      //     child: const Text('Sign in with Google'),
      //   ),
      // ),
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.07,
          child: Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 18),
                minimumSize:
                    Size.fromWidth(MediaQuery.of(context).size.width * 0.4),
                foregroundColor: AppColors.firstColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(30),
                  ),
                ),
              ),
              icon: Image.asset(
                'assets/images/google_sign_in_logo.png',
                width: 24,
                height: 24,
              ),
              label: const Text('Sign in with Google'),
              onPressed: () async {
                User? user = await _authService.signInWithGoogle();
                if (user != null && context.mounted) {
                  // Navigate to Home Screen
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => MainScreen()));
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
