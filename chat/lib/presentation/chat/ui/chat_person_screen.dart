import 'dart:async';
import 'package:chatapp/model/message_model.dart';
import 'package:chatapp/model/user_model.dart';
import 'package:chatapp/presentation/call/ui/call_attend_screen.dart';
import 'package:chatapp/presentation/shared/utils/chat_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../shared/riverpod/user_data_provider.dart';
import '../../shared/services/notification_service/notification_service.dart';

class ChatPersonScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  const ChatPersonScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatPersonScreen> createState() => _ChatPersonScreenState();
}

class _ChatPersonScreenState extends ConsumerState<ChatPersonScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final Service service = Service();
  Timer? _typingTimer;
  bool _isTyping = false;
  StreamSubscription? _messageSubscription;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_onTextChanged);
    _startMessageSubscription();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _messageSubscription?.cancel();
    _updateTypingStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _lifecycleState = state);
    if (state == AppLifecycleState.resumed) {
      _startMessageSubscription();
    } else {
      _messageSubscription?.cancel();
    }
  }

  void _onTextChanged() {
    if (!_isTyping && _messageController.text.isNotEmpty) {
      _updateTypingStatus(true);
    } else if (_isTyping && _messageController.text.isEmpty) {
      _updateTypingStatus(false);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) _updateTypingStatus(false);
    });
  }

  Future<void> _updateTypingStatus(bool typing) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    setState(() => _isTyping = typing);
    
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'typing': {currentUserId: typing}
    }, SetOptions(merge: true));
  }

  void _startMessageSubscription() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || _lifecycleState != AppLifecycleState.resumed) return;

    _messageSubscription?.cancel();
    _messageSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (_lifecycleState == AppLifecycleState.resumed) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'isRead': true});
        }
      }
    });
  }
  //
  // final TextEditingController _messageController = TextEditingController();
  // final Service service = Service();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final otherUserAsync = ref.watch(singleUserProvider(widget.otherUserId));
    final currentUserData = ref.watch(currentUserDataStreamProvider).value;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
          builder: (context, snapshot) {
            String titleSuffix = "";
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final typingMap = data['typing'] as Map<String, dynamic>?;
              if (typingMap != null && typingMap[widget.otherUserId] == true) {
                titleSuffix = "typing...";
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (titleSuffix.isNotEmpty)
                  Text(titleSuffix, style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontStyle: FontStyle.italic)),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.video_call, color: theme.colorScheme.primary),
            onPressed: () => _startVideoCall(context, ref),
          ),
          otherUserAsync.when(
            data: (otherUser) {
              if (otherUser == null) return const SizedBox.shrink();
              final isBlocked = currentUserData?.blockedList.contains(widget.otherUserId) ?? false;

              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) => _handleMenuAction(context, value, otherUser, isBlocked, currentUserId),
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
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
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

                final docs = snapshot.data?.docs ?? [];
                final messages = docs.map((doc) => MessageModel.fromFirestore(doc)).toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemBuilder: (_, i) {
                    final message = messages[i];
                    final isMe = message.senderId == currentUserId;

                    // Date grouping logic
                    bool showDateHeader = false;
                    String dateHeaderText = "";
                    if (i == messages.length - 1) {
                      showDateHeader = true;
                      dateHeaderText = _formatDateHeader(message.timestamp);
                    } else {
                      final prevMessage = messages[i + 1];
                      if (!_isSameDay(message.timestamp, prevMessage.timestamp)) {
                        showDateHeader = true;
                        dateHeaderText = _formatDateHeader(message.timestamp);
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(dateHeaderText, theme),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isMe ? 20 : 0),
                                      bottomRight: Radius.circular(isMe ? 0 : 20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        message.text,
                                        style: TextStyle(
                                          color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTime(message.timestamp),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: (isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant).withOpacity(0.7),
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.done_all,
                                              size: 14,
                                              color: message.isRead ? Colors.blue.shade300 : theme.colorScheme.onPrimary.withOpacity(0.5),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: Icon(Icons.send, color: theme.colorScheme.onPrimary, size: 20),
                      onPressed: () => _sendMessage(ref),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(WidgetRef ref) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    final currentUserData = ref.read(currentUserDataStreamProvider).value;

    final messageData = {
      'text': text,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    // Use consistent collection 'chats' and subcollection 'messages'
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add(messageData);

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'participants': [currentUserId, widget.otherUserId],
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessage': text,
    }, SetOptions(merge: true));

    final senderName = currentUserData?.displayName ?? 'A user';
    await service.sendNotification(senderName, text, widget.otherUserId);

    _messageController.clear();
    _updateTypingStatus(false);
  }

  Future<void> _startVideoCall(BuildContext context, WidgetRef ref) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final currentUserData = ref.read(currentUserDataStreamProvider).value;
      final currentUserName = currentUserData?.displayName ?? 'Unknown';

      // 1. Signal the call
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'participants': [currentUserId, widget.otherUserId],
        'callingData': {
          'calling': true,
          'callerId': currentUserId,
          'callerName': currentUserName,
        },
      }, SetOptions(merge: true));

      // 2. Add to history
      await FirebaseFirestore.instance.collection('callHistory').add({
        'participants': [currentUserId, widget.otherUserId],
        'callerId': currentUserId,
        'receiverId': widget.otherUserId,
        'callerName': currentUserName,
        'receiverName': widget.otherUserName,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'video',
        'status': 'initiated',
      });

      // 3. Navigate
      Get.to(() => VideoCallPage(
            channelId: widget.chatId,
            remoteName: widget.otherUserName,
          ));
    } catch (e) {
      debugPrint("Error starting call: $e");
      Get.snackbar("Error", "Could not start call: $e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _buildDateHeader(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return "Today";
    if (dateToCheck == yesterday) return "Yesterday";
    
    // Manual format: 12 Jan 2025
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? "PM" : "AM";
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  void _handleMenuAction(BuildContext context, String action, UserModel user, bool isBlocked, String? currentUserId) async {
    final theme = Theme.of(context);
    if (action == 'profile') {
      _showProfileDialog(context, user, theme);
    } else if (action == 'block_toggle' && currentUserId != null) {
      final docRef = FirebaseFirestore.instance.collection('Users').doc(currentUserId);
      if (isBlocked) {
        await docRef.update({
          'blockedList': FieldValue.arrayRemove([widget.otherUserId])
        });
      } else {
        await docRef.update({
          'blockedList': FieldValue.arrayUnion([widget.otherUserId])
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${user.displayName} has been ${isBlocked ? 'unblocked' : 'blocked'}")),
      );
    }
  }

  void _showProfileDialog(BuildContext context, UserModel user, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: theme.colorScheme.surface,
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileItem(theme, Icons.person_outline, "Name", user.displayName ?? 'Unknown'),
                  const SizedBox(height: 16),
                  _profileItem(theme, Icons.email_outlined, "Email", user.email ?? 'No email'),
                  const SizedBox(height: 16),
                  _profileItem(theme, Icons.info_outline, "Bio", user.bio ?? 'Elite Chat User'),
                ],
              ),
            ),
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
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
