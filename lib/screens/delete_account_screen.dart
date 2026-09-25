import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/account_deletion_service.dart';
import '../theme/app_theme.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({
    super.key,
    required this.email,
    required this.requiresPassword,
    required this.onDelete,
  });

  final String? email;
  final bool requiresPassword;
  final Future<void> Function(String? password) onDelete;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _deleting = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_deleting || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            'Your account, all saved cars, and their expiry dates will be '
            'permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep account'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.palette.error),
            child: Text(widget.requiresPassword
                ? 'Delete permanently'
                : 'Verify with Google & delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.onDelete(widget.requiresPassword ? _password.text : null);
      // Authentication normally removes this route when deletion completes.
      if (mounted) {
        _password.clear();
        if (ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      }
    } on GoogleSignInException catch (error) {
      if (mounted) {
        setState(() => _error = error.code == GoogleSignInExceptionCode.canceled
            ? 'Verification cancelled. Your account has not been deleted.'
            : 'Could not verify your Google account. Please try again.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authError(error.code));
    } on AccountDeletionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Could not delete your account. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String get _googleVerification =>
      'Google will ask you to choose an account to confirm it’s you. '
      'Select ${widget.email ?? 'the Google account shown above'}. '
      'After verification, your Car Alerts account will be permanently deleted. '
      'Your Google account will not be deleted.';

  String _authError(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'missing-password' =>
          widget.requiresPassword
              ? 'Your password was not accepted. Please check it and try again.'
              : 'Could not verify your Google account. Please try again.',
        'user-mismatch' =>
          'That is a different account. Select ${widget.email ?? 'the account you are deleting'} '
              'to continue. Nothing has been deleted.',
        'requires-recent-login' =>
          'Please sign in again, then return here to delete your account.',
        'network-request-failed' => 'Check your connection and try again.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        'unsupported-provider' =>
          'This sign-in method cannot be verified here. Please contact support.',
        _ => 'Could not verify your account. Please sign in again and retry.',
      };

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_deleting,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Delete account'),
            automaticallyImplyLeading: !_deleting,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Icon(Icons.person_remove_outlined,
                          color: context.palette.error, size: 40),
                      const SizedBox(height: 24),
                      Text('Permanently delete your account',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Text(
                        'This removes your Car Alerts account, saved cars, '
                        'expiry dates, and saved account settings. '
                        'Reminders on this device will be cancelled.',
                        style: TextStyle(
                            color: context.palette.muted, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Text('This cannot be undone.',
                          style: TextStyle(
                              color: context.palette.error,
                              fontWeight: FontWeight.w700)),
                      if (widget.email != null) ...[
                        const SizedBox(height: 24),
                        Text(widget.email!,
                            style: TextStyle(
                                color: context.palette.ink,
                                fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 20),
                      if (widget.requiresPassword)
                        TextFormField(
                          controller: _password,
                          enabled: !_deleting,
                          obscureText: _hidePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Current password',
                            helperText:
                                'Verify your identity to delete this account.',
                            helperMaxLines: 2,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            suffixIcon: IconButton(
                              onPressed: _deleting
                                  ? null
                                  : () => setState(
                                      () => _hidePassword = !_hidePassword),
                              tooltip: _hidePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              icon: Icon(_hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter your current password.'
                              : null,
                        )
                      else
                        Text(_googleVerification,
                            style: TextStyle(
                                color: context.palette.muted, height: 1.5)),
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          child: Text(_error!,
                              style: TextStyle(
                                  color: context.palette.error, height: 1.5)),
                        ),
                      ],
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: _deleting ? null : _delete,
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                        ),
                        icon: const Icon(Icons.delete_forever_outlined),
                        label: Text(
                            _deleting ? 'Deleting account…' : 'Delete account'),
                      ),
                      if (_deleting) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                        const Text('Keep the app open while deletion finishes.',
                            textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
