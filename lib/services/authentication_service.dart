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
