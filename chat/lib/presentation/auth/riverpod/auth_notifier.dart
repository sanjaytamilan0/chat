import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../app_route/route_name.dart';
import '../../../utills/app_toast.dart';
import 'auth_state.dart';
import 'user_auth.dart';

final authProvider = Provider<UserAuth>((ref) {
  return UserAuth();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.read(authProvider));
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final UserAuth auth;

  AuthStateNotifier(this.auth) : super(AuthState(user: auth.getCurrentUser()));

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final error = await auth.signIn(email, password);
    
    if (error == null) {
      state = state.copyWith(isLoading: false, user: auth.getCurrentUser());
      AppToast.success("Login Successful!");
      Get.offAllNamed(AppRoutes.home);
    } else {
      state = state.copyWith(isLoading: false, error: error);
      AppToast.error(error);
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    final error = await auth.signUp(email, password);
    
    if (error == null) {
      final user = auth.getCurrentUser();
      if (user != null) {
        await createUserInFireStore(user.uid, email, name);
      }
      state = state.copyWith(isLoading: false, user: user);
      AppToast.success("Registration Successful!");
      Get.offAllNamed(AppRoutes.home);
    } else {
      state = state.copyWith(isLoading: false, error: error);
      AppToast.error(error);
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
    state = AuthState();
  }

  Future<void> createUserInFireStore(String userId, String email, String name) async {
    final userDoc = FirebaseFirestore.instance.collection('Users').doc(userId);

    await userDoc.set({
      'id': userId,
      'email': email,
      'name': name,
      'createdAt': Timestamp.now(),
    });
  }


}
