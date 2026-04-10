import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/riverpod/user_data_provider.dart';
import '../../shared/services/notification_service/notification_service.dart';

class ChatPersonScreen extends ConsumerWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  ChatPersonScreen({required this.chatId, required this.otherUserName, required this.otherUserId});

  final TextEditingController _messageController = TextEditingController();
  final Service service = Service();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(otherUserName),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final message = messages[i];
                    final isMe = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;

                    return ListTile(
                      title: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            message['text'] ?? '',
                            style: TextStyle(color: isMe ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20)),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(ref),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(WidgetRef ref) async {
    final text = _messageController.text;
    if (text.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final currentUserData = ref.read(currentUserDataStreamProvider).value;

    final messageData = {
      'text': text,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Use consistent collection 'chats' and subcollection 'messages'
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add(messageData);

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUserId, otherUserId],
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessage': text,
    }, SetOptions(merge: true));

    final senderName = currentUserData?.displayName ?? 'A user';
    await service.sendNotification(senderName, text, otherUserId);

    _messageController.clear();
  }
}
