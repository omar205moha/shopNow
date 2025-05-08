import 'package:cloud_firestore/cloud_firestore.dart';

/// 8. Dispute
class Dispute {
  final String id;
  final DocumentReference orderRef;
  final DocumentReference initiatorRef;
  final String reason;
  final String status;
  final String? resolution;
  final DateTime createdAt;
  final DateTime updatedAt;

  Dispute({
    required this.id,
    required this.orderRef,
    required this.initiatorRef,
    required this.reason,
    required this.status,
    this.resolution,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dispute.fromMap(String id, Map<String, dynamic> data) => Dispute(
        id: id,
        orderRef: data['orderRef'],
        initiatorRef: data['initiatorRef'],
        reason: data['reason'],
        status: data['status'],
        resolution: data['resolution'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'orderRef': orderRef,
        'initiatorRef': initiatorRef,
        'reason': reason,
        'status': status,
        if (resolution != null) 'resolution': resolution,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
