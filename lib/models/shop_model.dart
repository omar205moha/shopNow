import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_now_mobile/models/address.dart';

class Shop {
  final String id;
  final DocumentReference userRef;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final String? logoUrl;
  final double? rating;
  final int? reviewCount;
  final int? productCount;
  final int? orderCount;
  final Address address;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shop({
    required this.id,
    required this.userRef,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.logoUrl,
    this.rating,
    this.reviewCount,
    this.productCount,
    this.orderCount,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Shop.fromMap(Map<String, dynamic> data) => Shop(
        id: data['id'],
        userRef: data['userRef'],
        name: data['name'],
        description: data['description'],
        coverImageUrl: data['coverImage'],
        logoUrl: data['logoUrl'],
        rating: data['rating'],
        reviewCount: data['reviewCount'],
        productCount: data['productCount'],
        orderCount: data['orderCount'],
        address: Address.fromMap(data['address']),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'userRef': userRef,
        'name': name,
        if (description != null) 'description': description,
        if (coverImageUrl != null) 'coverImage': coverImageUrl,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (rating != null) 'rating': rating,
        if (reviewCount != null) 'reviewCount': reviewCount,
        if (productCount != null) 'productCount': productCount,
        if (orderCount != null) 'orderCount': orderCount,
        'address': address.toMap(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
