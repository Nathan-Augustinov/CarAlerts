import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Continues the native launch branding while authentication is restored.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF172D38),
          body: Stack(children: [
            Center(
                child: Image(
                    image: const AssetImage('assets/images/splash_mark.png'),
                    width: defaultTargetPlatform == TargetPlatform.android
                        ? 200
                        : 288,
                    height: defaultTargetPlatform == TargetPlatform.android
                        ? 200
                        : 288,
                    filterQuality: FilterQuality.high)),
            const Positioned.fill(
                child: SafeArea(
                    child: Column(children: [
              Spacer(),
              Text('Car Alerts',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              SizedBox(height: 8),
              Text('Every car. Every deadline.',
                  style: TextStyle(color: Color(0xFF9EDBD0), fontSize: 13)),
              SizedBox(height: 48),
            ]))),
          ]),
        ),
      );
}
