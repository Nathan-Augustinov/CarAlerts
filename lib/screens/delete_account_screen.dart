import '../l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.deleteYourAccount),
        content: Text(AppLocalizations.of(context)!.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.keepAccount),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.palette.error),
            child: Text(widget.requiresPassword
                ? AppLocalizations.of(context)!.deletePermanently
                : AppLocalizations.of(context)!.verifyWithGoogleDelete),
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
            ? AppLocalizations.of(context)!
                .verificationCancelledYourAccountHasNotBeenDeleted
            : AppLocalizations.of(context)!
                .couldNotVerifyYourGoogleAccountPleaseTryAgain);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authError(error.code));
    } on AccountDeletionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!
            .couldNotDeleteYourAccountCheckYourConnectionAndTryAgain);
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String get _googleVerification =>
      AppLocalizations.of(context)!.googleDeletion(
          widget.email ?? AppLocalizations.of(context)!.googleAccountAbove);

  String _authError(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'missing-password' =>
          widget.requiresPassword
              ? AppLocalizations.of(context)!
                  .yourPasswordWasNotAcceptedPleaseCheckItAndTryAgain
              : AppLocalizations.of(context)!
                  .couldNotVerifyYourGoogleAccountPleaseTryAgain,
        'user-mismatch' => AppLocalizations.of(context)!.differentAccount(
            widget.email ?? AppLocalizations.of(context)!.accountBeingDeleted),
        'requires-recent-login' => AppLocalizations.of(context)!
            .pleaseSignInAgainThenReturnHereToDeleteYourAccount,
        'network-request-failed' =>
          AppLocalizations.of(context)!.checkYourConnectionAndTryAgain,
        'too-many-requests' =>
          AppLocalizations.of(context)!.tooManyAttemptsPleaseWaitAndTryAgain,
        'unsupported-provider' => AppLocalizations.of(context)!
            .thisSignInMethodCannotBeVerifiedHerePleaseContactSupport,
        _ => AppLocalizations.of(context)!
            .couldNotVerifyYourAccountPleaseSignInAgainAndRetry,
      };

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_deleting,
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.deleteAccount),
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
                      Text(
                          AppLocalizations.of(context)!
                              .permanentlyDeleteYourAccount,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.deletionDetails,
                        style: TextStyle(
                            color: context.palette.muted, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context)!.thisCannotBeUndone,
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
                            labelText:
                                AppLocalizations.of(context)!.currentPassword,
                            helperText: AppLocalizations.of(context)!
                                .verifyYourIdentityToDeleteThisAccount,
                            helperMaxLines: 2,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            suffixIcon: IconButton(
                              onPressed: _deleting
                                  ? null
                                  : () => setState(
                                      () => _hidePassword = !_hidePassword),
                              tooltip: _hidePassword
                                  ? AppLocalizations.of(context)!.showPassword
                                  : AppLocalizations.of(context)!.hidePassword,
                              icon: Icon(_hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? AppLocalizations.of(context)!
                                  .enterYourCurrentPassword
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
                        label: Text(_deleting
                            ? AppLocalizations.of(context)!.deletingAccount
                            : AppLocalizations.of(context)!.deleteAccount),
                      ),
                      if (_deleting) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                            AppLocalizations.of(context)!
                                .keepTheAppOpenWhileDeletionFinishes,
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
