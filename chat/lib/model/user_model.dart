import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? bio;
  final List<String> friendList;
  final List<String> blockedList;
  final String? statusText;
  final int? statusColor;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.bio,
    this.friendList = const [],
    this.blockedList = const [],
    this.statusText,
    this.statusColor,
  });

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserModel(
      uid: doc.id,
      email: data?['email'],
      displayName: data?['name'],
      bio: data?['bio'],
      friendList: data?['friendList'] != null
          ? List<String>.from(data!['friendList'])
          : [],
      blockedList: data?['blockedList'] != null
          ? List<String>.from(data!['blockedList'])
          : [],
      statusText: data?['statusText'],
      statusColor: data?['statusColor'],
    );
  }
}
