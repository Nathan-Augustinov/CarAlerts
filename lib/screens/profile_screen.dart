import 'delete_account_screen.dart';
import '../services/account_deletion_service.dart';
import '../services/appearance_controller.dart';
import '../widgets/appearance_setting.dart';
import '../theme/app_theme.dart';
import '../services/notifications_service.dart';
import 'feedback_screen.dart';
import 'package:car_alerts/services/authentication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/notification_permission_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  bool _signingOut = false;

  final _permissionService = NotificationPermissionService();
  NotificationPermission? _permission;
  ReminderStatus? scheduleStatus;
  bool _checkingPermission = true;
  bool _permissionAction = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    try {
      final permission = await _permissionService.status();
      final schedule = await NotificationsService.instance.refresh();
      if (!mounted) return;
      setState(() {
        _permission = permission;
        scheduleStatus = schedule;
        _checkingPermission = false;
        _permissionError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _permission = null;
        _checkingPermission = false;
        _permissionError = 'Unable to check. Tap to retry.';
      });
    }
  }

  Future<void> _enableNotifications() async {
    if (_permissionAction || _checkingPermission) return;
    setState(() => _permissionAction = true);
    try {
      final status = await _permissionService.status();
      if (!mounted) return;
      if (status == NotificationPermission.notRequested) {
        await _permissionService.request();
      } else if (status == NotificationPermission.disabled) {
        await _permissionService.openSettings();
      }
      await _refreshPermission();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Could not open notification settings. Please try again.'),
      ));
    } finally {
      if (mounted) setState(() => _permissionAction = false);
    }
  }

  Widget _notificationSetting() {
    final enabled = _permission == NotificationPermission.enabled;
    final loading = _checkingPermission || _permissionAction;
    final label = _checkingPermission
        ? 'Checking…'
        : _permissionError != null
            ? 'Status unavailable'
            : enabled
                ? (scheduleStatus == ReminderStatus.failed
                    ? 'Reminders will retry automatically'
                    : 'Enabled')
                : 'Not enabled';
    return InkWell(
      onTap: loading || enabled
          ? null
          : _permissionError != null
              ? _refreshPermission
              : _enableNotifications,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: context.palette.background,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.notifications_none_outlined,
                color: context.palette.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Notifications',
                    style: TextStyle(
                        color: context.palette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(label,
                    style: TextStyle(
                        color: enabled
                            ? context.palette.accent
                            : context.palette.muted,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600)),
                if (!enabled && !_checkingPermission) ...[
                  const SizedBox(height: 4),
                  Text(
                      _permissionError ??
                          (_permission == NotificationPermission.notRequested
                              ? 'Tap to allow expiry reminders.'
                              : 'Tap to enable in phone settings.'),
                      style: TextStyle(
                          color: context.palette.muted,
                          fontSize: 12,
                          height: 1.5)),
                ],
              ])),
          const SizedBox(width: 12),
          SizedBox(
            height: 42,
            width: 24,
            child: Center(
                child: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: context.palette.accent))
                    : enabled
                        ? Icon(Icons.check_circle_outline,
                            color: context.palette.accent, size: 22)
                        : Icon(Icons.chevron_right,
                            color: context.palette.muted)),
          ),
        ]),
      ),
    );
  }

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
      backgroundColor: context.palette.background,
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            Text('MAKE IT YOURS',
                style: TextStyle(
                    color: context.palette.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
            const SizedBox(height: 10),
            Text('Settings',
                style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1)),
            const SizedBox(height: 6),
            Text('Your account and preferences, in one place.',
                style: TextStyle(color: context.palette.muted, fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: context.palette.banner,
                  borderRadius: BorderRadius.circular(20)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                      color:
                          context.palette.bannerAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.person_outline,
                      color: context.palette.bannerAccent, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('YOUR ACCOUNT',
                          style: TextStyle(
                              color: context.palette.bannerAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(name == null || name.isEmpty ? 'Your profile' : name,
                          style: TextStyle(
                              color: context.palette.onBanner,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(user?.email ?? 'No email available',
                          style: TextStyle(
                              color: context.palette.bannerMuted,
                              fontSize: 13,
                              height: 1.5)),
                    ])),
              ]),
            ),
            const SizedBox(height: 28),
            _heading(
                'Preferences', 'Personal touches to make Car Alerts yours.'),
            _card([
              AppearanceSetting(controller: AppearanceController.instance),
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.palette.divider),
              _notificationSetting(),
            ]),
            const SizedBox(height: 28),
            _heading('Help & feedback', 'Help shape what comes next.'),
            _card([
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                leading:
                    Icon(Icons.forum_outlined, color: context.palette.accent),
                title: Text('Share feedback',
                    style: TextStyle(
                        color: context.palette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                subtitle: Text('Suggest an improvement or report a problem.',
                    style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 12,
                        height: 1.5)),
                trailing:
                    Icon(Icons.chevron_right, color: context.palette.muted),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const FeedbackScreen())),
              ),
            ]),
            const SizedBox(height: 28),
            _heading('Account', 'Manage your session on this device.'),
            _card([
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: Icon(Icons.logout, color: context.palette.error),
                title: Text(_signingOut ? 'Signing out…' : 'Sign out',
                    style: TextStyle(
                        color: context.palette.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                subtitle: Text('Your cars stay saved to your account.',
                    style:
                        TextStyle(color: context.palette.muted, fontSize: 12)),
                trailing: _signingOut
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: context.palette.accent))
                    : Icon(Icons.chevron_right,
                        color: context.palette.muted, size: 20),
                onTap: _signingOut ? null : _signOut,
              ),
            ]),
            const SizedBox(height: 28),
            _heading('Delete account',
                'Permanently remove your account and saved data.'),
            _card([
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                leading: Icon(Icons.person_remove_outlined,
                    color: context.palette.error),
                title: Text('Delete account',
                    style: TextStyle(
                        color: context.palette.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                subtitle: Text('This action cannot be undone.',
                    style:
                        TextStyle(color: context.palette.muted, fontSize: 12)),
                trailing:
                    Icon(Icons.chevron_right, color: context.palette.muted),
                onTap: _signingOut || user == null
                    ? null
                    : () {
                        final service = AccountDeletionService();
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => DeleteAccountScreen(
                            email: user.email,
                            requiresPassword: user.providerData.any(
                                (provider) =>
                                    provider.providerId == 'password'),
                            onDelete: (password) =>
                                service.delete(password: password),
                          ),
                        ));
                      },
              ),
            ]),
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.directions_car_outlined,
                  color: context.palette.muted, size: 18),
              const SizedBox(width: 8),
              Text('Car Alerts',
                  style: TextStyle(
                      color: context.palette.muted,
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
              style: TextStyle(
                  color: context.palette.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(
                  color: context.palette.muted, fontSize: 13, height: 1.5)),
        ]),
      );

  Widget _card(List<Widget> children) => Material(
        color: context.palette.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: context.palette.border)),
        child: Column(children: children),
      );
}
