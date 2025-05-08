import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final DocumentReference userRef;
  final String type;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.userRef,
    required this.type,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) => AppNotification(
        userRef: data['userRef'],
        type: data['type'],
        payload: data['payload'],
        isRead: data['isRead'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'userRef': userRef,
        'type': type,
        'payload': payload,
        'isRead': isRead,
        'createdAt': createdAt,
      };
}
