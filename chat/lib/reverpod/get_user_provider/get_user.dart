import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/user_model.dart';

class UserFetch{

}

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  UserNotifier() : super(const AsyncValue.loading()) {
    _getUser();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _getUser() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        state = AsyncValue.data(UserModel.fromFirebaseUser(user));
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier();
});
