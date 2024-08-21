import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_person_screen/chat_person_screen.dart';

class ChatScreen extends StatelessWidget {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(currentUserId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        final currentUserData = snapshot.data?.data() as Map<String, dynamic>?;

        if (currentUserData == null || currentUserData['friendList'] == null) {
          return const Center(child: Text('No friends found'));
        }

        final friendIds = List<String>.from(currentUserData['friendList']);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .where(FieldPath.documentId, whereIn: friendIds)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            final friends = snapshot.data?.docs ?? [];

            if (friends.isEmpty) {
              return const Center(child: Text('No friends found'));
            }

            return ListView.builder(
              itemCount: friends.length,
              itemBuilder: (_, i) {
                final friend = friends[i];
                return ListTile(
                  onTap: () async {
                    // Generate chatId
                    final chatId = _generateChatId(currentUserId!, friend.id);

                    // Navigate to ChatPersonScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPersonScreen(
                          chatId: chatId,
                          otherUserName: friend['name'],
                        ),
                      ),
                    );
                  },
                  title: Text(friend['name']),
                );
              },
            );
          },
        );
      },
    );
  }

  String _generateChatId(String userId1, String userId2) {
    // This function generates a unique chat ID based on the user IDs
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }
}
