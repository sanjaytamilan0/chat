import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // added for kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../../../model/user_model.dart';
import '../../../../model/status_model.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final oneSignalLoginProvider = Provider<void>((ref) {
  if (kIsWeb) return; // Web Guard

  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user != null) {
    OneSignal.login(user.uid);
    print("OneSignal Logged in: ${user.uid}");
  } else {
    OneSignal.logout();
    print("OneSignal Logged out");
  }
});

final currentUserDataStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('Users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

final friendsListStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final userData = ref.watch(currentUserDataStreamProvider).value;

  if (userData == null || userData.friendList.isEmpty) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('Users')
      .where(FieldPath.documentId, whereIn: userData.friendList)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('Users')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
});

final blockedUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final userData = ref.watch(currentUserDataStreamProvider).value;

  if (userData == null || userData.blockedList.isEmpty) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('Users')
      .where(FieldPath.documentId, whereIn: userData.blockedList)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
});

/// Streams active incoming calls for the current user
final incomingCallProvider = StreamProvider<QuerySnapshot>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return Stream.empty();

  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: currentUserId)
      .where('callingData.calling', isEqualTo: true)
      .snapshots();
});

final singleUserProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('Users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

final activeStatusesStreamProvider = StreamProvider<Map<String, List<StatusModel>>>((ref) {
  final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
  
  return FirebaseFirestore.instance
      .collection('statuses')
      .where('createdAt', isGreaterThan: twoHoursAgo)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        final Map<String, List<StatusModel>> grouped = {};
        for (var doc in snapshot.docs) {
          final status = StatusModel.fromFirestore(doc);
          if (!grouped.containsKey(status.uid)) {
            grouped[status.uid] = [];
          }
          grouped[status.uid]!.add(status);
        }
        return grouped;
      });
});
