import 'package:chatapp/presentation/call/ui/call_attend_screen.dart';
import 'package:chatapp/presentation/shared/utils/chat_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../riverpod/contact_notifier.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactState = ref.watch(contactProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.teal,
      ),
      body: contactState.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(child: Text('No contacts found.'));
          }
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(contact.displayName?[0].toUpperCase() ?? '?'),
                ),
                title: Text(contact.displayName ?? 'No name'),
                subtitle: Text(contact.email ?? 'No email'),
                trailing: const Icon(Icons.video_call, color: Colors.teal),
                onTap: () async {
                  if (currentUserId == null) return;

                  final chatId = ChatUtils.generateChatId(currentUserId, contact.uid);

                  try {
                    // Fetch current user name
                    final currentUserDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUserId).get();
                    final currentUserName = currentUserDoc.data()?['name'] ?? 'Unknown';

                    // 1. Signal the call in the chats collection
                    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
                      'participants': [currentUserId, contact.uid],
                      'callingData': {
                        'calling': true,
                        'callerId': currentUserId,
                        'callerName': currentUserName,
                      },
                    }, SetOptions(merge: true));

                    // 2. Create a record in callHistory
                    await FirebaseFirestore.instance.collection('callHistory').add({
                      'participants': [currentUserId, contact.uid],
                      'callerId': currentUserId,
                      'receiverId': contact.uid,
                      'callerName': currentUserName,
                      'receiverName': contact.displayName ?? 'Unknown',
                      'timestamp': FieldValue.serverTimestamp(),
                      'type': 'video',
                      'status': 'initiated',
                    });

                    // 3. Navigate to Call Page
                    if (context.mounted) {
                      Get.to(() => VideoCallPage(
                        channelId: chatId, 
                        remoteName: contact.displayName ?? 'Unknown'
                      ));
                    }
                  } catch (e) {
                    debugPrint("Error starting call: $e");
                    Get.snackbar("Error", "Could not start call: $e", 
                                snackPosition: SnackPosition.BOTTOM);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
