import 'package:cloud_firestore/cloud_firestore.dart';

/// 3. Category
class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromMap(String id, Map<String, dynamic> data) => Category(
        id: id,
        name: data['name'],
        imageUrl: data['imageUrl'],
        order: data['order'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'order': order,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
