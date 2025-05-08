// PAYMENT SERVICE
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/services/paypal_service.dart';
import 'package:shop_now_mobile/services/stripe_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal();

  static PaymentService get instance => _instance;

  Future<bool> processCardPayment(int amount) async {
    await StripeService.instance.makePayment(
      amount: amount,
      currency: 'USD',
    );
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('Error processing card payment: $e');
      return false;
    }
  }

  Future<bool> processPayPalPayment(BuildContext context, double amount) async {
    try {
      bool result = false;

      await Get.to(() => PayPalPaymentScreen(
            amount: amount,
            currency: 'USD',
            description: 'Payment for your order',
            onFinish: (success) {
              result = success;
            },
          ));

      return result;
    } catch (e) {
      debugPrint('Error processing PayPal payment: $e');
      return false;
    }
  }
}
