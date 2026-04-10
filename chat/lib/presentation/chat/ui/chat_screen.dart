import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/riverpod/user_data_provider.dart';
import '../../shared/utils/chat_utils.dart';
import 'chat_person_screen.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListStreamProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return const Center(child: Text('No friends found'));
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (_, i) {
            final friend = friends[i];
            final chatId = ChatUtils.generateChatId(currentUserId ?? '', friend.uid);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    offset: Offset(0, 0.4),
                    blurRadius: 0.2,
                  )
                ],
              ),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPersonScreen(
                        chatId: chatId,
                        otherUserName: friend.displayName ?? 'Unknown',
                        otherUserId: friend.uid,
                      ),
                    ),
                  );
                },
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(friend.displayName ?? 'Unknown'),
                subtitle: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
                  builder: (context, chatDocSnapshot) {
                    if (chatDocSnapshot.hasData && chatDocSnapshot.data!.exists) {
                      final chatData = chatDocSnapshot.data!.data() as Map<String, dynamic>?;
                      return Text(
                        chatData?['lastMessage'] ?? 'Click to chat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      );
                    }
                    return const Text('Start chatting...');
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
