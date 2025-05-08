import 'package:cloud_firestore/cloud_firestore.dart';

/// 6.1 Order Timeline Event
class OrderTimelineEvent {
  final String id;
  final String type;
  final DateTime timestamp;
  final GeoPoint? location;

  OrderTimelineEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.location,
  });

  factory OrderTimelineEvent.fromMap(String id, Map<String, dynamic> data) => OrderTimelineEvent(
        id: id,
        type: data['type'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        location: data['location'],
      );

  Map<String, dynamic> toMap() => {
        'type': type,
        'timestamp': timestamp,
        if (location != null) 'location': location,
      };
}
