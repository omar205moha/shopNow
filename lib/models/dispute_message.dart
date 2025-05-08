import 'package:cloud_firestore/cloud_firestore.dart';

/// 8.1 Dispute Message
class DisputeMessage {
  final String id;
  final DocumentReference senderRef;
  final String message;
  final DateTime timestamp;

  DisputeMessage({
    required this.id,
    required this.senderRef,
    required this.message,
    required this.timestamp,
  });

  factory DisputeMessage.fromMap(String id, Map<String, dynamic> data) => DisputeMessage(
        id: id,
        senderRef: data['senderRef'],
        message: data['message'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'senderRef': senderRef,
        'message': message,
        'timestamp': timestamp,
      };
}
