import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_alerts/services/user_settings_service.dart';
import 'package:flutter/material.dart';
import '../services/authentication_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final _authService = AuthenticationService();
  late final _settingsService = UserSettingsService();
  bool _signingIn = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _creatingAccount = false;
  bool _hidePassword = true;
  String? _notice;
  String? _operation;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String _authError(FirebaseAuthException error) => switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Email or password is incorrect. Try again or reset your password.',
        'email-already-in-use' =>
          'This email already has an account. Sign in or reset your password.',
        'weak-password' ||
        'password-does-not-meet-requirements' =>
          'Choose a stronger password that meets the account password requirements.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        'network-request-failed' => 'Check your connection and try again.',
        'operation-not-allowed' =>
          'This sign-in method is not available right now.',
        _ => 'Unable to complete your request. Please try again.',
      };

  Future<void> _authenticate(String operation) async {
    if (_signingIn) return;
    if (operation == 'email' && !_formKey.currentState!.validate()) return;
    if (operation == 'reset' && !_emailKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _signingIn = true;
      _operation = operation;
      _error = null;
      _notice = null;
    });
    try {
      if (operation == 'reset') {
        await _authService.resetPassword(_email.text);
        if (mounted) {
          setState(() => _notice =
              'If an account exists for this email, you’ll receive a password reset link.');
        }
      } else {
        final user = operation == 'google'
            ? await _authService.signInWithGoogle()
            : _creatingAccount
                ? await _authService.createAccount(_email.text, _password.text)
                : await _authService.signInWithEmail(
                    _email.text, _password.text);
        if (user != null) {
          // Authentication state controls navigation. Settings failures must not
          // report that a successfully authenticated account failed to sign in.
          try {
            await _settingsService.initializeUserSettings(user);
          } catch (_) {
            debugPrint('User settings initialization could not complete.');
          }
        }
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authError(error));
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Unable to complete your request. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _signingIn = false;
          _operation = null;
        });
      }
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: Icon(icon, color: context.palette.muted),
        filled: true,
        fillColor: context.palette.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.palette.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.palette.accent, width: 2)),
        errorMaxLines: 3,
      );

  Widget _emailForm() => AutofillGroup(
          child: Form(
        key: _formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            key: _emailKey,
            controller: _email,
            enabled: !_signingIn,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: _decoration('Email address', Icons.mail_outline),
            validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                    .hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter a valid email address.',
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _password,
            enabled: !_signingIn,
            obscureText: _hidePassword,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: [
              _creatingAccount
                  ? AutofillHints.newPassword
                  : AutofillHints.password
            ],
            textInputAction:
                _creatingAccount ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!_creatingAccount) _authenticate('email');
            },
            decoration: _decoration('Password', Icons.lock_outline).copyWith(
              hintText: _creatingAccount ? 'At least 6 characters' : null,
              suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.palette.muted)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your password.';
              if (_creatingAccount && value.length < 6) {
                return 'Use at least 6 characters.';
              }
              return null;
            },
          ),
          if (_creatingAccount) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmation,
              enabled: !_signingIn,
              obscureText: _hidePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _authenticate('email'),
              decoration: _decoration('Confirm password', Icons.lock_outline),
              validator: (value) => value == null || value.isEmpty
                  ? 'Confirm your password.'
                  : value != _password.text
                      ? 'Passwords do not match.'
                      : null,
            ),
          ] else
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _signingIn ? null : () => _authenticate('reset'),
                  style: TextButton.styleFrom(
                      foregroundColor: context.palette.accent),
                  child: Text(_operation == 'reset'
                      ? 'Sending reset link…'
                      : 'Forgot password?'),
                )),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _signingIn ? null : () => _authenticate('email'),
            style: FilledButton.styleFrom(
                backgroundColor: context.palette.accent,
                foregroundColor: context.palette.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: Text(
                _operation == 'email'
                    ? 'Please wait…'
                    : _creatingAccount
                        ? 'Create account'
                        : 'Sign in',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: _signingIn
                ? null
                : () => setState(() {
                      _creatingAccount = !_creatingAccount;
                      _password.clear();
                      _confirmation.clear();
                      _formKey.currentState?.reset();
                      _error = null;
                      _notice = null;
                      _hidePassword = true;
                    }),
            style:
                TextButton.styleFrom(foregroundColor: context.palette.accent),
            child: Text(_creatingAccount
                ? 'Already have an account? Sign in'
                : 'New here? Create an account'),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(child: Divider(color: context.palette.border)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('or',
                        style: TextStyle(color: context.palette.muted))),
                Expanded(child: Divider(color: context.palette.border)),
              ])),
        ]),
      ));

  Widget _welcomeBanner(BuildContext context) {
    return Container(
      key: const ValueKey('welcome-banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: context.palette.banner,
          borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.shield_outlined,
              color: context.palette.bannerAccent, size: 22),
          const SizedBox(width: 8),
          Expanded(
              child: Text('A LITTLE PEACE OF MIND',
                  style: TextStyle(
                      color: context.palette.bannerAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2))),
        ]),
        const SizedBox(height: 16),
        Text('Less to remember.\nMore road ahead.',
            style: TextStyle(
                color: context.palette.onBanner,
                fontSize: 27,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        ...[
          const SizedBox(height: 14),
          Text('Insurance · Inspections · Vignettes',
              style: TextStyle(
                  color: context.palette.bannerMuted,
                  fontSize: 12,
                  height: 1.4)),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.palette.background,
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(children: [
              _welcomeBanner(context),
              const SizedBox(height: 14),
              Expanded(
                  child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      key: const ValueKey('auth-content'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            _creatingAccount
                                ? 'Create your account'
                                : 'Welcome',
                            style: TextStyle(
                                color: context.palette.ink,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 12),
                        _emailForm(),
                        SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: context.palette.surface,
                                foregroundColor: context.palette.ink,
                                disabledBackgroundColor:
                                    context.palette.surface,
                                side: BorderSide(color: context.palette.border),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _signingIn
                                  ? null
                                  : () => _authenticate('google'),
                              icon: _operation == 'google'
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.palette.accent))
                                  : Image.asset(
                                      'assets/images/google_sign_in_logo.png',
                                      width: 22,
                                      height: 22),
                              label: Text(
                                  _operation == 'google'
                                      ? 'Signing in…'
                                      : 'Sign in with Google',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            )),
                        if (_notice != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(_notice!,
                                    style: TextStyle(
                                        color: context.palette.accent,
                                        height: 1.5))),
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Semantics(
                                liveRegion: true,
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: context.palette.error,
                                        fontSize: 13,
                                        height: 1.5))),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
            ]),
          ),
        ))),
      );
}
