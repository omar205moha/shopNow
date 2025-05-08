import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final DocumentReference categoryRef;
  final String categoryName;
  final DocumentReference brandRef;
  final String brandName;
  final double price;
  final double originalPrice;
  final String unit;
  final int stock;
  final bool featured;
  final String imageUrl;
  final DocumentReference shopRef;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryRef,
    required this.categoryName,
    required this.brandRef,
    required this.brandName,
    required this.price,
    required this.originalPrice,
    required this.unit,
    required this.stock,
    required this.featured,
    required this.imageUrl,
    required this.shopRef,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> data) => Product(
        id: data["id"],
        name: data['name'],
        description: data['description'],
        categoryRef: data['categoryRef'],
        categoryName: data['categoryName'],
        brandRef: data['brandRef'],
        brandName: data['brandName'],
        price: data['price'],
        originalPrice: data['originalPrice'],
        unit: data['unit'],
        stock: data['stock'],
        featured: data['featured'],
        imageUrl: data['imageUrl'] ?? "",
        shopRef: data['shopRef'],
        createdAt: data['createdAt'].runtimeType == String
            ? DateTime.parse(data['createdAt'])
            : (data['createdAt'] as Timestamp).toDate(),
        updatedAt: data['updatedAt'].runtimeType == String
            ? DateTime.parse(data['updatedAt'])
            : (data['updatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'categoryRef': categoryRef,
        'categoryName': categoryName,
        'brandRef': brandRef,
        'brandName': brandName,
        'price': price,
        'originalPrice': originalPrice,
        'unit': unit,
        'stock': stock,
        'featured': featured,
        'imageUrl': imageUrl,
        'shopRef': shopRef,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
