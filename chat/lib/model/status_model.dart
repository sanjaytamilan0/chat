import 'package:cloud_firestore/cloud_firestore.dart';

class StatusTextElement {
  final String text;
  final double x;
  final double y;

  StatusTextElement({
    required this.text,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'x': x,
      'y': y,
    };
  }

  factory StatusTextElement.fromMap(Map<String, dynamic> map) {
    return StatusTextElement(
      text: map['text'] ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.5,
      y: (map['y'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class StatusModel {
  final String id;
  final String uid;
  final String userName;
  final String text; // Legacy support
  final List<StatusTextElement> texts;
  final int color;
  final DateTime createdAt;

  StatusModel({
    required this.id,
    required this.uid,
    required this.userName,
    required this.text,
    required this.texts,
    required this.color,
    required this.createdAt,
  });

  factory StatusModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle list of texts
    final List<StatusTextElement> textList = [];
    if (data['texts'] != null) {
      for (var item in (data['texts'] as List)) {
        textList.add(StatusTextElement.fromMap(item as Map<String, dynamic>));
      }
    }

    return StatusModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      text: data['text'] ?? '',
      texts: textList,
      color: data['color'] ?? 0xFF10B981,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'userName': userName,
      'text': text,
      'texts': texts.map((e) => e.toMap()).toList(),
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
