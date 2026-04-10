import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final List<String> friendList;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.friendList = const [],
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
      friendList: data?['friendList'] != null
          ? List<String>.from(data!['friendList'])
          : [],
    );
  }
}
