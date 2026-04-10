import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utills/app_toast.dart';
import '../../auth/riverpod/user_auth.dart';
import '../../chat/ui/chat_person_screen.dart';
import '../../shared/utils/chat_utils.dart';
import 'email_match_state.dart';

final emailMatchProvider = StateNotifierProvider<EmailMatchNotifier, EmailMatchState>((ref) => EmailMatchNotifier());

class EmailMatchNotifier extends StateNotifier<EmailMatchState> {
  EmailMatchNotifier() : super(EmailMatchState());
  final authSetting = UserAuth();
  String? userId;

  Future<void> checkEmailMatch(BuildContext context, String enteredEmail) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      CollectionReference users = FirebaseFirestore.instance.collection('Users');
      QuerySnapshot querySnapshot = await users.where('email', isEqualTo: enteredEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot matchedUser = querySnapshot.docs.first;
        final currentUserId = authSetting.auth.currentUser?.uid;

        if (currentUserId != null) {
          userId = matchedUser['id'];

          await users.doc(currentUserId).update({
            'friendList': FieldValue.arrayUnion([matchedUser.id])
          });

          final chatId = ChatUtils.generateChatId(currentUserId, matchedUser.id);
          
          state = state.copyWith(isLoading: false, isSuccess: true);

          if (context.mounted) {
            Navigator.pop(context); // Close dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPersonScreen(
                  chatId: chatId,
                  otherUserName: matchedUser['name'],
                  otherUserId: matchedUser.id,
                ),
              ),
            );
          }
        }
      } else {
        state = state.copyWith(isLoading: false, error: 'Email not found');
        AppToast.error('Email not found');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      AppToast.error(e.toString());
    }
  }
}
