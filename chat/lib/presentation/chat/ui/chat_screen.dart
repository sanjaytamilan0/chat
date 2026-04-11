import 'package:chatapp/presentation/chat/ui/edit_status_screen.dart';
import 'package:chatapp/presentation/chat/ui/view_status_screen.dart';
import 'package:chatapp/model/user_model.dart';
import 'package:chatapp/presentation/shared/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../shared/riverpod/user_data_provider.dart';
import '../../shared/utils/chat_utils.dart';
import 'chat_person_screen.dart';

import '../widgets/snake_torch_header.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friendsAsync = ref.watch(friendsListStreamProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        toolbarHeight: 150,
        centerTitle: true,
        backgroundColor: Colors.transparent, // Let the header background show
        elevation: 0,
        title: Column(
          children: [
            const SnakeTorchHeader(),
            const SizedBox(height: 16),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
              ),
                child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 22),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      body: friendsAsync.when(
        data: (friends) {
          final filteredFriends = friends.where((f) {
            final name = (f.displayName ?? '').toLowerCase();
            return name.contains(_searchQuery);
          }).toList();

          final isSearching = _searchQuery.isNotEmpty;

          return ListView.builder(
            itemCount: filteredFriends.length + (isSearching ? 0 : 2), // Hide headers if searching
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (_, i) {
              if (!isSearching) {
                if (i == 0) {
                  return _buildStatusRow(friends, theme);
                }
                if (i == 1) {
                  return _buildAddFriendHeader(context, theme);
                }
              }
              
              final friend = filteredFriends[isSearching ? i : i - 2]; 
              final chatId = ChatUtils.generateChatId(currentUserId ?? '', friend.uid);

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
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        child: Icon(Icons.person, color: theme.colorScheme.primary),
                      ),
                    ),
                    title: Text(
                      friend.displayName ?? 'Unknown',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
                      builder: (context, chatDocSnapshot) {
                        String lastMsg = 'Start chatting...';
                        if (chatDocSnapshot.hasData && chatDocSnapshot.data!.exists) {
                          final chatData = chatDocSnapshot.data!.data() as Map<String, dynamic>?;
                          lastMsg = chatData?['lastMessage'] ?? 'Click to chat';
                        }
                        return Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        );
                      },
                    ),
                    trailing: Consumer(
                      builder: (context, ref, _) {
                        final currentUser = ref.watch(currentUserDataStreamProvider).value;
                        final isBlocked = currentUser?.blockedList.contains(friend.uid) ?? false;
                        
                        return PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          offset: const Offset(0, 40),
                          onSelected: (value) async {
                            if (value == 'profile') {
                              _showProfileDialog(context, friend, theme);
                            } else if (value == 'block_toggle') {
                              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                              if (currentUserId != null) {
                                final batch = FirebaseFirestore.instance.collection('Users').doc(currentUserId);
                                if (isBlocked) {
                                  await batch.update({
                                    'blockedList': FieldValue.arrayRemove([friend.uid])
                                  });
                                } else {
                                  await batch.update({
                                    'blockedList': FieldValue.arrayUnion([friend.uid])
                                  });
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("${friend.displayName} has been ${isBlocked ? 'unblocked' : 'blocked'}")),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text("View Profile"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'block_toggle',
                              child: Row(
                                children: [
                                  Icon(isBlocked ? Icons.check_circle_outline : Icons.block, 
                                       size: 20, 
                                       color: isBlocked ? Colors.green : Colors.red),
                                  const SizedBox(width: 12),
                                  Text(
                                    isBlocked ? "Unblock" : "Block", 
                                    style: TextStyle(color: isBlocked ? Colors.green : Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAddFriendHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => DialogUtils.showAddFriendDialog(context, _emailController),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add New Friend",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    "Start a new conversation",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: theme.colorScheme.primary.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(List<UserModel> friends, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            "STATUS UPDATES",
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: Consumer(
            builder: (context, ref, _) {
              final statusMapAsync = ref.watch(activeStatusesStreamProvider);
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              
              return statusMapAsync.when(
                data: (statusMap) {
                  // Filter friends based on who has active statuses
                  final friendsWithStatus = friends.where((f) => statusMap.containsKey(f.uid)).toList();
                  final myStatuses = statusMap[currentUserId] ?? [];
                  final hasMyStatus = myStatuses.isNotEmpty;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: friendsWithStatus.length + 1, // Always show "My Status"
                    itemBuilder: (context, index) {
                      final isMe = index == 0;
                      final userUid = isMe ? currentUserId : friendsWithStatus[index - 1].uid;
                      final userStatuses = statusMap[userUid] ?? [];
                      final hasStatus = userStatuses.isNotEmpty;
                      
                      // Get name and initials
                      String displayName;
                      if (isMe) {
                        displayName = "My Status";
                      } else {
                        displayName = friendsWithStatus[index - 1].displayName ?? "User";
                      }
                      final initials = _getInitials(displayName);

                      // Status appearance logic
                      Color accentColor;
                      if (hasStatus) {
                        accentColor = Color(userStatuses.first.color);
                      } else {
                        accentColor = theme.colorScheme.primary;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (isMe && !hasStatus) {
                                    Get.to(() => const EditStatusScreen());
                                  } else if (hasStatus) {
                                    Get.to(() => ViewStatusScreen(statuses: userStatuses));
                                  }
                                },
                                child: Container(
                                  height: 64,
                                  width: 64,
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: hasStatus ? accentColor : theme.colorScheme.outlineVariant,
                                      width: 2.5
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: hasStatus ? accentColor : theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isMe)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => Get.to(() => const EditStatusScreen()),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: theme.colorScheme.surface, width: 2),
                                      ),
                                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                displayName.split(' ').first,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                  color: isMe ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text("Error: $e")),
              );
            },
          ),
        ),
        const Divider(indent: 20, endIndent: 20, thickness: 0.5),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _showProfileDialog(BuildContext context, dynamic friend, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: theme.colorScheme.surface,
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Profile Icon
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
            ),
            
            // Profile Details
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileItem(theme, Icons.person_outline, "Name", friend.displayName ?? 'Unknown'),
                  const SizedBox(height: 16),
                  _profileItem(theme, Icons.email_outlined, "Email", friend.email ?? 'No email'),
                  const SizedBox(height: 16),
                  _profileItem(theme, Icons.info_outline, "Bio", friend.bio ?? 'Elite Chat User'),
                ],
              ),
            ),

            // Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(ThemeData theme, IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
