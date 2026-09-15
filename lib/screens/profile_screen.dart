import 'package:car_alerts/services/authentication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _ink = Color(0xFF172D38);
const _teal = Color(0xFF15766D);
const _muted = Color(0xFF647681);
const _background = Color(0xFFF3F6F7);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      // The app's authentication listener shows sign-in after sign-out.
      await AuthenticationService().signOutFromGoogle();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not sign out. Please try again.'),
      ));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            const Text('MAKE IT YOURS',
                style: TextStyle(
                    color: _teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
            const SizedBox(height: 10),
            const Text('Settings',
                style: TextStyle(
                    color: _ink,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1)),
            const SizedBox(height: 6),
            const Text('Your account and preferences, in one place.',
                style: TextStyle(color: _muted, fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: _ink, borderRadius: BorderRadius.circular(20)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                      color: const Color(0xFF29444D),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.person_outline,
                      color: Color(0xFF9EDBD0), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('YOUR ACCOUNT',
                          style: TextStyle(
                              color: Color(0xFF9EDBD0),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(name == null || name.isEmpty ? 'Your profile' : name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(user?.email ?? 'No email available',
                          style: const TextStyle(
                              color: Color(0xFFC3D0D6),
                              fontSize: 13,
                              height: 1.5)),
                    ])),
              ]),
            ),
            const SizedBox(height: 28),
            _heading(
                'Preferences', 'Personal touches for your everyday drive.'),
            _card([
              _setting(Icons.palette_outlined, 'Appearance',
                  'The app currently uses a light theme.'),
              const Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: Color(0xFFEAF0F2)),
              _setting(Icons.notifications_none_outlined, 'Notifications',
                  'Notification preferences aren’t available yet.'),
            ]),
            const SizedBox(height: 28),
            _heading('Help & feedback', 'Help shape what comes next.'),
            _card([
              _setting(Icons.chat_bubble_outline, 'Suggest an improvement',
                  'In-app feedback isn’t available yet.'),
            ]),
            const SizedBox(height: 28),
            _heading('Account', 'Manage your session on this device.'),
            _card([
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: const Icon(Icons.logout, color: Color(0xFFAD3939)),
                title: Text(_signingOut ? 'Signing out…' : 'Sign out',
                    style: const TextStyle(
                        color: Color(0xFFAD3939),
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                subtitle: const Text('Your cars stay saved to your account.',
                    style: TextStyle(color: _muted, fontSize: 12)),
                trailing: _signingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _teal))
                    : const Icon(Icons.chevron_right, color: _muted, size: 20),
                onTap: _signingOut ? null : _signOut,
              ),
            ]),
            const SizedBox(height: 32),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.directions_car_outlined, color: _muted, size: 18),
              SizedBox(width: 8),
              Text('Car Alerts',
                  style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ]),
          ],
        ),
      ))),
    );
  }

  Widget _heading(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _ink, fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(color: _muted, fontSize: 13, height: 1.5)),
        ]),
      );

  Widget _card(List<Widget> children) => Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE0E7EA))),
        child: Column(children: children),
      );

  Widget _setting(IconData icon, String title, String description) => Padding(
        padding: const EdgeInsets.all(18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _background, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: _teal, size: 22)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(description,
                    style: const TextStyle(
                        color: _muted, fontSize: 12, height: 1.5)),
                const SizedBox(height: 10),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Not available yet',
                        style: TextStyle(
                            color: _muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600))),
              ])),
        ]),
      );
}
