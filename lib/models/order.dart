import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_now_mobile/models/order_item.dart';

/// 6. Order
class Order {
  final String id;
  final DocumentReference buyerRef;
  final DocumentReference? shopperRef;
  final DocumentReference shopRef;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final GeoPoint storeLocation;
  final GeoPoint deliveryLocation;
  final String geohashStore;
  final String geohashDelivery;
  final String? distanceText;
  final String? timeText;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.buyerRef,
    this.shopperRef,
    required this.shopRef,
    required this.items,
    required this.total,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.storeLocation,
    required this.deliveryLocation,
    required this.geohashStore,
    required this.geohashDelivery,
    this.distanceText,
    this.timeText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromMap(String id, Map<String, dynamic> data) => Order(
        id: id,
        buyerRef: data['buyerRef'],
        shopperRef: data['shopperRef'],
        shopRef: data['shopRef'],
        items: (data['items'] as List).map((e) => OrderItem.fromMap(e)).toList(),
        total: data['total'],
        status: data['status'],
        requestedAt: (data['requestedAt'] as Timestamp).toDate(),
        acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
        pickedUpAt: (data['pickedUpAt'] as Timestamp?)?.toDate(),
        deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
        storeLocation: data['storeLocation'],
        deliveryLocation: data['deliveryLocation'],
        geohashStore: data['geohashStore'],
        geohashDelivery: data['geohashDelivery'],
        distanceText: data['distanceText'],
        timeText: data['timeText'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'buyerRef': buyerRef,
        if (shopperRef != null) 'shopperRef': shopperRef,
        'shopRef': shopRef,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'status': status,
        'requestedAt': requestedAt,
        if (acceptedAt != null) 'acceptedAt': acceptedAt,
        if (pickedUpAt != null) 'pickedUpAt': pickedUpAt,
        if (deliveredAt != null) 'deliveredAt': deliveredAt,
        'storeLocation': storeLocation,
        'deliveryLocation': deliveryLocation,
        'geohashStore': geohashStore,
        'geohashDelivery': geohashDelivery,
        if (distanceText != null) 'distanceText': distanceText,
        if (timeText != null) 'timeText': timeText,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
