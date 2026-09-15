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

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken
    );

    UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user;
  }

  Future<void> signOutFromGoogle() async {
    await _googleInitialization;
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
