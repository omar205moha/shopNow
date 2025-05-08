import 'package:cloud_firestore/cloud_firestore.dart';

/// 1.1 ShopperProfile
class ShopperProfile {
  final String id;
  final String verificationStatus;
  final bool availability;
  final GeoPoint? currentLocation;
  final String? geohash;
  final double? avgRating;
  final int? ratingCount;
  final String? governmentIdUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopperProfile({
    required this.id,
    required this.verificationStatus,
    required this.availability,
    this.currentLocation,
    this.governmentIdUrl,
    this.geohash,
    this.avgRating,
    this.ratingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopperProfile.fromMap(String id, Map<String, dynamic> data) {
    final stats = data['ratingStats'] as Map<String, dynamic>;
    return ShopperProfile(
      id: id,
      verificationStatus: data['verificationStatus'],
      governmentIdUrl: data['governmentIdUrl'],
      availability: data['availability'],
      currentLocation: data['currentLocation'],
      geohash: data['geohash'],
      avgRating: stats['avg'],
      ratingCount: stats['count'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'verificationStatus': verificationStatus,
        'governmentIdUrl': governmentIdUrl,
        'availability': availability,
        'currentLocation': currentLocation,
        'geohash': geohash,
        'ratingStats': {'avg': avgRating, 'count': ratingCount},
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
