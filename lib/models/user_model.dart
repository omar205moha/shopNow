import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_now_mobile/models/address.dart';

/// 1. User
class UserModel {
  final String id;
  final String role;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final Address? address;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.role,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.address,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    final name = data['name'] as Map<String, dynamic>;
    return UserModel(
      id: data['id'],
      role: data['role'],
      email: data['email'],
      phone: data['phone'],
      firstName: name['first'],
      lastName: name['last'],
      address: data['address'] != null ? Address.fromMap(data['address']) : null,
      profileImage: data['profileImage'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role,
        'email': email,
        'profileImage': profileImage,
        if (phone != null) 'phone': phone,
        'name': {'first': firstName, 'last': lastName},
        if (address != null) 'address': address!.toMap(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
