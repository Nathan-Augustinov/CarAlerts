import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/sign_in_screen.dart';
import '../services/local_car_store.dart';

Future<void> openLocalSignIn(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'sign_in'),
        builder: (_) => const SignInScreen(returnToLocal: true)));
Future<bool> allowLocalCarCreation(BuildContext context) async {
  if (FirebaseAuth.instance.currentUser != null ||
      LocalCarStore.instance.registration == null) {
    return true;
  }
  await showLocalCarLimit(context);
  return false;
}

Future<void> showLocalCarLimit(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  final signIn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(l.localCarLimitTitle),
            content: Text(l.localCarLimitBody),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.localMaybeLater)),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l.signIn)),
            ],
          ));
  if (signIn == true && context.mounted) await openLocalSignIn(context);
}
