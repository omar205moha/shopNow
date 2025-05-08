import 'package:cloud_firestore/cloud_firestore.dart';

/// OrderItem nested in Order
class OrderItem {
  final DocumentReference productRef;
  final String name;
  final int quantity;
  final String unit;
  final double price;

  OrderItem({
    required this.productRef,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) => OrderItem(
        productRef: data['productRef'],
        name: data['name'],
        quantity: data['quantity'],
        unit: data['unit'],
        price: data['price'],
      );

  Map<String, dynamic> toMap() => {
        'productRef': productRef,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'price': price,
      };
}
