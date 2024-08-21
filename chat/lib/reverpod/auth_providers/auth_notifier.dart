
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_auth.dart';

final authProvider = Provider<UserAuth>((ref) {
  return UserAuth();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, User?>((ref) {
  return AuthStateNotifier(ref.read(authProvider));
});

class AuthStateNotifier extends StateNotifier<User?> {
  final UserAuth auth;

  AuthStateNotifier(this.auth) : super(auth.getCurrentUser());

  Future<void> signIn(String email, String password) async {
    final success = await auth.signIn(email, password);
    if (success) {
      state = auth.getCurrentUser();
    }
  }

  Future<void> signUp(String email, String password) async {
    final success = await auth.signUp(email, password);
    if (success) {
      state = auth.getCurrentUser();
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
    state = null;
  }

  Future<void> createUserInFireStore(String userId, String email) async {
    final userDoc = FirebaseFirestore.instance.collection('Users').doc(userId);

    await userDoc.set({
      'email': email,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> sendMessage(String chatId, String senderId, String receiverId, String message) async {
    final messagesRef = FirebaseFirestore.instance
        .collection('Chats')
        .doc(chatId)
        .collection('Messages');

    await messagesRef.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'messageText': message,
      'timestamp': Timestamp.now(),
    });
  }

  // Stream<List<Message>> getMessages(String chatId) {
  //   return FirebaseFirestore.instance
  //       .collection('Chats')
  //       .doc(chatId)
  //       .collection('Messages')
  //       .orderBy('timestamp')
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  // }


}
