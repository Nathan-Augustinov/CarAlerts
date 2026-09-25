import '../l10n/app_localizations.dart';
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
            Positioned.fill(
                child: SafeArea(
                    child: Column(children: [
              const Spacer(),
              const Text('CarAlerts',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.splashTagline,
                  style: const TextStyle(
                      color: Color(0xFF9EDBD0), fontSize: 13)),
              const SizedBox(height: 48),
            ]))),
          ]),
        ),
      );
}
