import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An unknown error occurred during signup.";
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
      throw e.message ?? "An unknown error occurred during login.";
    } catch (e) {
      throw "An error occurred: $e";
    }
  }

  // LOGOUT FUNCTION
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Unable to send password reset email.";
    } catch (e) {
      throw "An error occurred: $e";
    }
  }

  Future<String> verifyPasswordResetCode(String code) async {
    try {
      return await _auth.verifyPasswordResetCode(code);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "This password reset link is invalid or expired.";
    } catch (e) {
      throw "An error occurred: $e";
    }
  }

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
      throw e.message ?? "Unable to update password.";
    } catch (e) {
      throw "An error occurred: $e";
    }
  }

  // GET ID TOKEN
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }
}
