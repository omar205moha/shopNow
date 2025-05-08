import 'package:cloud_firestore/cloud_firestore.dart';

class Brand {
  final String id;
  final String name;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Brand({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Brand.fromMap(String id, Map<String, dynamic> data) => Brand(
        id: id,
        name: data['name'],
        logoUrl: data['logoUrl'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        if (logoUrl != null) 'logoUrl': logoUrl,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
