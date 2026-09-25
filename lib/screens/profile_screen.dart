import '../widgets/crashlytics_test_controls.dart';
import 'package:car_alerts/services/crash_reporting_service.dart';
import '../services/language_controller.dart';
import '../widgets/language_setting.dart';
import '../l10n/app_localizations.dart';
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
    } catch (error, stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'check_notification_permission');
      if (!mounted) return;
      setState(() {
        _permission = null;
        _checkingPermission = false;
        _permissionError = 'unavailable';
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
    } catch (error, stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'request_notification_permission');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.notificationSettingsError),
      ));
    } finally {
      if (mounted) setState(() => _permissionAction = false);
    }
  }

  Widget _notificationSetting() {
    final enabled = _permission == NotificationPermission.enabled;
    final loading = _checkingPermission || _permissionAction;
    final label = _checkingPermission
        ? AppLocalizations.of(context)!.checking
        : _permissionError != null
            ? AppLocalizations.of(context)!.statusUnavailable
            : enabled
                ? (scheduleStatus == ReminderStatus.failed
                    ? AppLocalizations.of(context)!.reminderRetry
                    : AppLocalizations.of(context)!.enabled)
                : AppLocalizations.of(context)!.notEnabled;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      leading: Icon(Icons.notifications_none_outlined,
          color: context.palette.accent),
      title: Text(AppLocalizations.of(context)!.notifications,
          style: TextStyle(
              color: context.palette.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color:
                      enabled ? context.palette.accent : context.palette.muted,
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w600)),
          if (!enabled && !_checkingPermission)
            Text(
                _permissionError != null
                    ? AppLocalizations.of(context)!.permissionError
                    : _permission == NotificationPermission.notRequested
                        ? AppLocalizations.of(context)!.allowReminders
                        : AppLocalizations.of(context)!.enableInSettings,
                style: TextStyle(
                    color: context.palette.muted, fontSize: 12, height: 1.5)),
        ],
      ),
      trailing: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: context.palette.accent))
          : enabled
              ? Icon(Icons.check_circle_outline, color: context.palette.accent)
              : Icon(Icons.chevron_right, color: context.palette.muted),
      onTap: loading || enabled
          ? null
          : _permissionError != null
              ? _refreshPermission
              : _enableNotifications,
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      // The app's authentication listener shows sign-in after sign-out.
      await AuthenticationService().signOutFromGoogle();
    } catch (error, stack) {
      CrashReportingService.instance
          .report(error, stack, operation: 'sign_out');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.signOutError),
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
            if (CrashReportingService.testControls)
              const CrashlyticsTestControls(),
            Text(AppLocalizations.of(context)!.makeItYours,
                style: TextStyle(
                    color: context.palette.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.settings,
                style: TextStyle(
                    color: context.palette.ink,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1)),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context)!.settingsDescription,
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
                      Text(AppLocalizations.of(context)!.yourAccount,
                          style: TextStyle(
                              color: context.palette.bannerAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(
                          name == null || name.isEmpty
                              ? AppLocalizations.of(context)!.yourProfile
                              : name,
                          style: TextStyle(
                              color: context.palette.onBanner,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(user?.email ?? AppLocalizations.of(context)!.noEmail,
                          style: TextStyle(
                              color: context.palette.bannerMuted,
                              fontSize: 13,
                              height: 1.5)),
                    ])),
              ]),
            ),
            const SizedBox(height: 28),
            _heading(AppLocalizations.of(context)!.preferences,
                AppLocalizations.of(context)!.preferencesDescription),
            _card([
              AppearanceSetting(controller: AppearanceController.instance),
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.palette.divider),
              LanguageSetting(controller: LanguageController.instance),
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: context.palette.divider),
              _notificationSetting(),
            ]),
            const SizedBox(height: 28),
            _heading(AppLocalizations.of(context)!.helpFeedback,
                AppLocalizations.of(context)!.helpDescription),
            _card([
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                leading:
                    Icon(Icons.forum_outlined, color: context.palette.accent),
                title: Text(AppLocalizations.of(context)!.shareFeedback,
                    style: TextStyle(
                        color: context.palette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                subtitle: Text(
                    AppLocalizations.of(context)!.feedbackDescription,
                    style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 12,
                        height: 1.5)),
                trailing:
                    Icon(Icons.chevron_right, color: context.palette.muted),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    settings: const RouteSettings(name: 'feedback'),
                    builder: (_) => const FeedbackScreen())),
              ),
            ]),
            const SizedBox(height: 28),
            _heading(AppLocalizations.of(context)!.account,
                AppLocalizations.of(context)!.accountDescription),
            _card([
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: Icon(Icons.logout, color: context.palette.error),
                title: Text(
                    _signingOut
                        ? AppLocalizations.of(context)!.signingOut
                        : AppLocalizations.of(context)!.signOut,
                    style: TextStyle(
                        color: context.palette.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                subtitle: Text(AppLocalizations.of(context)!.carsStaySaved,
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
            _heading(AppLocalizations.of(context)!.deleteAccount,
                AppLocalizations.of(context)!.deleteDescription),
            _card([
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                leading: Icon(Icons.person_remove_outlined,
                    color: context.palette.error),
                title: Text(AppLocalizations.of(context)!.deleteAccount,
                    style: TextStyle(
                        color: context.palette.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                subtitle: Text(AppLocalizations.of(context)!.cannotUndo,
                    style:
                        TextStyle(color: context.palette.muted, fontSize: 12)),
                trailing:
                    Icon(Icons.chevron_right, color: context.palette.muted),
                onTap: _signingOut || user == null
                    ? null
                    : () {
                        final service = AccountDeletionService();
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          settings: const RouteSettings(name: 'delete_account'),
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
              Text('CarAlerts',
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
