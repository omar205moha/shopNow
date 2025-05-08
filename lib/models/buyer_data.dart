import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_now_mobile/models/payment_method.dart';

class BuyerData {
  final List<PaymentMethod> paymentMethods;
  final List<DocumentReference> favorites;
  final Map<String, dynamic>? orderPrefs;

  BuyerData({
    required this.paymentMethods,
    required this.favorites,
    this.orderPrefs,
  });

  factory BuyerData.fromMap(String id, Map<String, dynamic> data) => BuyerData(
        paymentMethods:
            (data['paymentMethods'] as List).map((e) => PaymentMethod.fromMap(e)).toList(),
        favorites: List<DocumentReference>.from(data['favorites']),
        orderPrefs: data['orderPrefs'],
      );

  Map<String, dynamic> toMap() => {
        'paymentMethods': paymentMethods.map((e) => e.toMap()).toList(),
        'favorites': favorites,
        if (orderPrefs != null) 'orderPrefs': orderPrefs,
      };
}
