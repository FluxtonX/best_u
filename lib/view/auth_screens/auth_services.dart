import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is incorrectly formatted. Please enter a valid email.';
      case 'user-not-found':
        return 'No account exists with this email address. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please verify your password and try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please verify your credentials.';
      case 'email-already-in-use':
        return 'This email address is already registered. Please sign in instead.';
      case 'weak-password':
        return 'The password is too weak. It must be at least 6 characters long.';
      case 'network-request-failed':
        return 'Network Error: Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many login attempts. This account has been temporarily locked. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-verification-code':
        return 'The password reset code is invalid or has expired.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }

  // SIGN UP FUNCTION
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      throw "An error occurred: $e";
    }
  }

  // LOGIN FUNCTION
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      throw "An error occurred: $e";
    }
  }

  // GOOGLE SIGN IN FUNCTION
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled the flow
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      throw "Google Sign-In failed: $e";
    }
  }

  // LOGOUT FUNCTION
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // PASSWORD RESET LINK FUNCTION
  Future<void> sendPasswordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      throw "An error occurred: $e";
    }
  }

  // VERIFY PASSWORD RESET CODE FUNCTION
  Future<String> verifyPasswordResetCode(String code) async {
    try {
      return await _auth.verifyPasswordResetCode(code);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      throw "An error occurred: $e";
    }
  }

  // CONFIRM PASSWORD RESET FUNCTION
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      throw "An error occurred: $e";
    }
  }

  // GET ID TOKEN
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }
}
