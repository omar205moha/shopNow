import 'package:cloud_firestore/cloud_firestore.dart';

class AssignedOrder {
  final DocumentReference orderRef;
  final String status;
  final DateTime assignedAt;
  final DateTime lastUpdatedAt;

  AssignedOrder({
    required this.orderRef,
    required this.status,
    required this.assignedAt,
    required this.lastUpdatedAt,
  });

  factory AssignedOrder.fromMap(String id, Map<String, dynamic> data) => AssignedOrder(
        orderRef: data['orderRef'],
        status: data['status'],
        assignedAt: (data['assignedAt'] as Timestamp).toDate(),
        lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'orderRef': orderRef,
        'status': status,
        'assignedAt': assignedAt,
        'lastUpdatedAt': lastUpdatedAt,
      };
}
