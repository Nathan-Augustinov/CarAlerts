import 'package:car_alerts/services/user_settings_service.dart';
import 'package:flutter/material.dart';
import '../services/authentication_service.dart';

const _ink = Color(0xFF172D38);
const _teal = Color(0xFF15766D);
const _muted = Color(0xFF647681);
const _background = Color(0xFFF3F6F7);

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _authService = AuthenticationService();
  final _settingsService = UserSettingsService();
  bool _signingIn = false;
  String? _error;

  Future<void> _signIn() async {
    if (_signingIn) return;
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        // The app's auth listener opens the garage; don't push a second route.
        await _settingsService.initializeUserSettings(user);
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not sign in. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _background,
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: _teal, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.directions_car_outlined,
                        color: Colors.white, size: 24)),
                const SizedBox(width: 12),
                const Text('Car Alerts',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 36),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: _ink, borderRadius: BorderRadius.circular(24)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.shield_outlined,
                            color: Color(0xFF9EDBD0), size: 24),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text('A LITTLE PEACE OF MIND',
                                style: TextStyle(
                                    color: Color(0xFF9EDBD0),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5))),
                      ]),
                      const SizedBox(height: 24),
                      const Text('Less to remember.\nMore road ahead.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      const SizedBox(height: 14),
                      const Text(
                          'Keep your cars and their important dates together, wherever life takes you.',
                          style: TextStyle(
                              color: Color(0xFFC3D0D6),
                              fontSize: 14,
                              height: 1.6)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: const Color(0xFF29444D),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Row(children: [
                          Icon(Icons.event_available_outlined,
                              color: Color(0xFF9EDBD0), size: 28),
                          SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Every deadline, in one place',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                SizedBox(height: 5),
                                Text('Insurance · Inspections · Vignettes',
                                    style: TextStyle(
                                        color: Color(0xFFC3D0D6),
                                        fontSize: 12,
                                        height: 1.5)),
                              ])),
                        ]),
                      ),
                    ]),
              ),
              const SizedBox(height: 32),
              const Text('Welcome to your garage',
                  style: TextStyle(
                      color: _ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text(
                  'Sign in to add your first car or pick up where you left off.',
                  style: TextStyle(color: _muted, fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _ink,
                      disabledBackgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD4DEE2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _signingIn ? null : _signIn,
                    icon: _signingIn
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _teal))
                        : Image.asset('assets/images/google_sign_in_logo.png',
                            width: 22, height: 22),
                    label: Text(
                        _signingIn ? 'Signing in…' : 'Sign in with Google',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  )),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Semantics(
                      liveRegion: true,
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Color(0xFFAD3939),
                              fontSize: 13,
                              height: 1.5))),
                ),
              const SizedBox(height: 18),
              const Center(
                  child: Text('Your cars, linked to your Google account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 12))),
            ]),
          ),
        ))),
      );
}
