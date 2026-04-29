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
}
