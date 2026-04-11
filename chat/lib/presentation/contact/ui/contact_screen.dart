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
    final theme = Theme.of(context);
    final contactState = ref.watch(contactProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: contactState.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('Your contact list is empty', 
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: contacts.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        child: Text(
                          contact.displayName?[0].toUpperCase() ?? '?',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    title: Text(
                      contact.displayName ?? 'No name',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      contact.email ?? 'No email',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.video_call, color: theme.colorScheme.primary),
                    ),
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
                  ),
                ),
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
