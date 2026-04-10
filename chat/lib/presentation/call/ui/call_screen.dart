import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../riverpod/call_history_provider.dart';

class CallScreen extends ConsumerWidget {
  const CallScreen({super.key});

  Icon _getCallIcon(CallRecord record, String currentUserId) {
    if (record.isIncoming(currentUserId)) {
      return const Icon(Icons.call_received, color: Colors.green);
    } else {
      return const Icon(Icons.call_made, color: Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(callHistoryProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const Center(child: Text('No call history found.'));
        }
        return ListView.separated(
          itemCount: history.length,
          itemBuilder: (context, i) {
            final record = history[i];
            final isIncoming = record.isIncoming(currentUserId);
            final displayName = isIncoming ? record.callerName : record.receiverName;
            final timeStr = DateFormat('MMM d, h:mm a').format(record.timestamp);

            return ListTile(
              leading: _getCallIcon(record, currentUserId),
              title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(timeStr),
              trailing: Icon(record.type == 'video' ? Icons.videocam : Icons.call, color: Colors.teal),
              onTap: () {
                // Future enhancement: detailed log or call back
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
