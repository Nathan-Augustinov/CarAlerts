import 'notifications_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  // Initialization is shared across service instances and must run only once.
  static final Future<void> _googleInitialization =
      GoogleSignIn.instance.initialize();

  Future<User?> signInWithGoogle() async {
    await _googleInitialization;
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential =
        GoogleAuthProvider.credential(idToken: googleAuth.idToken);

    UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    return result.user;
  }

  Future<User?> createAccount(String email, String password) async {
    final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    return result.user;
  }

  Future<void> reauthenticateForDeletion(User user, String? password) async {
    final providers = user.providerData.map((provider) => provider.providerId);
    final AuthCredential credential;
    if (providers.contains('password') && user.email != null) {
      if (password == null || password.isEmpty) {
        throw FirebaseAuthException(code: 'missing-password');
      }
      credential =
          EmailAuthProvider.credential(email: user.email!, password: password);
    } else if (providers.contains('google.com')) {
      await _googleInitialization;
      final account = await _googleSignIn.authenticate();
      final googleProvider = user.providerData
          .firstWhere((provider) => provider.providerId == 'google.com');
      if (account.id != googleProvider.uid) {
        throw FirebaseAuthException(code: 'user-mismatch');
      }
      credential = GoogleAuthProvider.credential(
          idToken: account.authentication.idToken);
    } else {
      throw FirebaseAuthException(code: 'unsupported-provider');
    }
    // Reauthenticate the existing user; never sign into a different Google
    // account as a side effect of confirming deletion.
    await user.reauthenticateWithCredential(credential);
    await user.getIdToken(true);
  }

  Future<void> clearGoogleSession() async {
    await _googleInitialization;
    await _googleSignIn.signOut();
  }

  Future<void> resetPassword(String email) =>
      _firebaseAuth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOutFromGoogle() async {
    final usesGoogle = _firebaseAuth.currentUser?.providerData
            .any((provider) => provider.providerId == 'google.com') ??
        false;
    if (usesGoogle) {
      await _googleInitialization;
      await _googleSignIn.signOut();
    }
    await _firebaseAuth.signOut();
    await NotificationsService.instance.refresh();
  }
}
