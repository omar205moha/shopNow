import 'package:cloud_firestore/cloud_firestore.dart';

/// 7. Review
class Review {
  final String id;
  final DocumentReference orderRef;
  final DocumentReference reviewerRef;
  final DocumentReference revieweeRef;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.orderRef,
    required this.reviewerRef,
    required this.revieweeRef,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> data) => Review(
        id: id,
        orderRef: data['orderRef'],
        reviewerRef: data['reviewerRef'],
        revieweeRef: data['revieweeRef'],
        rating: data['rating'],
        comment: data['comment'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'orderRef': orderRef,
        'reviewerRef': reviewerRef,
        'revieweeRef': revieweeRef,
        'rating': rating,
        if (comment != null) 'comment': comment,
        'createdAt': createdAt,
      };
}
