import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../riverpod/call_history_provider.dart';

class CallScreen extends ConsumerWidget {
  const CallScreen({super.key});

  Icon _getCallIcon(BuildContext context, CallRecord record, String currentUserId) {
    final theme = Theme.of(context);
    if (record.isIncoming(currentUserId)) {
      return Icon(Icons.call_received, color: theme.colorScheme.error);
    } else {
      return Icon(Icons.call_made, color: theme.colorScheme.primary);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(callHistoryProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Call History'),
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: theme.colorScheme.primary.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No call records found', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: history.length,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, i) {
              final record = history[i];
              final isIncoming = record.isIncoming(currentUserId);
              final displayName = isIncoming ? record.callerName : record.receiverName;
              final timeStr = DateFormat('MMM d, h:mm a').format(record.timestamp);

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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: _getCallIcon(context, record, currentUserId),
                    ),
                    title: Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      timeStr,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    trailing: Icon(
                      record.type == 'video' ? Icons.videocam : Icons.call,
                      color: theme.colorScheme.primary,
                    ),
                    onTap: () {
                      // Future enhancement: detailed log or call back
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
