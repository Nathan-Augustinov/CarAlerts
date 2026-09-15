import 'package:firebase_auth/firebase_auth.dart';
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
        prefixIcon: Icon(icon, color: _muted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD4DEE2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _teal, width: 2)),
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
                      color: _muted)),
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
                  style: TextButton.styleFrom(foregroundColor: _teal),
                  child: Text(_operation == 'reset'
                      ? 'Sending reset link…'
                      : 'Forgot password?'),
                )),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _signingIn ? null : () => _authenticate('email'),
            style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
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
            style: TextButton.styleFrom(foregroundColor: _teal),
            child: Text(_creatingAccount
                ? 'Already have an account? Sign in'
                : 'New here? Create an account'),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(child: Divider(color: Color(0xFFD4DEE2))),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('or', style: TextStyle(color: _muted))),
                Expanded(child: Divider(color: Color(0xFFD4DEE2))),
              ])),
        ]),
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _background,
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
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
                      const SizedBox(height: 16),
                      const Text('Less to remember.\nMore road ahead.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      const SizedBox(height: 10),
                      const Text(
                          'Keep your cars and their important dates together, wherever life takes you.',
                          style: TextStyle(
                              color: Color(0xFFC3D0D6),
                              fontSize: 13,
                              height: 1.5)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFF29444D),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Row(children: [
                          Icon(Icons.event_available_outlined,
                              color: Color(0xFF9EDBD0), size: 26),
                          SizedBox(width: 12),
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
                                        fontSize: 11,
                                        height: 1.5)),
                              ])),
                        ]),
                      ),
                    ]),
              ),
              const SizedBox(height: 14),
              Text(_creatingAccount ? 'Create your account' : 'Welcome',
                  style: const TextStyle(
                      color: _ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5)),
              const SizedBox(height: 12),
              _emailForm(),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _ink,
                      disabledBackgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD4DEE2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed:
                        _signingIn ? null : () => _authenticate('google'),
                    icon: _operation == 'google'
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _teal))
                        : Image.asset('assets/images/google_sign_in_logo.png',
                            width: 22, height: 22),
                    label: Text(
                        _operation == 'google'
                            ? 'Signing in…'
                            : 'Sign in with Google',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  )),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Semantics(
                      liveRegion: true,
                      child: Text(_notice!,
                          style: const TextStyle(color: _teal, height: 1.5))),
                ),
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
            ]),
          ),
        ))),
      );
}
