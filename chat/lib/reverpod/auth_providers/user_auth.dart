import 'package:firebase_auth/firebase_auth.dart';

class UserAuth {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<bool> signIn(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print('Sign-In failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      await auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print('Sign-Up failed: ${e.toString()}');
      return false;
    }
  }

  User? getCurrentUser() {
    return auth.currentUser;
  }

  Future<void> signOut() async {
    await auth.signOut();
  }
}
