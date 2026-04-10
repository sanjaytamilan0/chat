import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final callHistoryProvider = StreamProvider<List<CallRecord>>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('callHistory')
      .where('participants', arrayContains: currentUserId)
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs.map((doc) => CallRecord.fromFirestore(doc)).toList();
    // Sort client-side to avoid needing a Firestore composite index
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  });
});

class CallRecord {
  final String id;
  final String callerId;
  final String receiverId;
  final String callerName;
  final String receiverName;
  final DateTime timestamp;
  final String type;
  final String status;

  CallRecord({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    required this.receiverName,
    required this.timestamp,
    required this.type,
    required this.status,
  });

  factory CallRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallRecord(
      id: doc.id,
      callerId: data['callerId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      callerName: data['callerName'] ?? 'Unknown',
      receiverName: data['receiverName'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'video',
      status: data['status'] ?? 'completed',
    );
  }

  bool isIncoming(String currentUserId) => receiverId == currentUserId;
}
