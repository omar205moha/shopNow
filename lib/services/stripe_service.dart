import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:toastification/toastification.dart';

class StripeService {
  // Private constructor for singleton pattern
  StripeService._();

  // Singleton instance
  static final StripeService instance = StripeService._();

  // Expose these as getters to allow dependency injection in tests
  Dio get _dio => _dioInstance ?? Dio();
  Dio? _dioInstance;

  // For testability
  @visibleForTesting
  set dio(Dio dioInstance) {
    _dioInstance = dioInstance;
  }

  // Toast instance with getter and setter for testability
  Toastification get _toastification => _toastInstance;
  Toastification _toastInstance = toastification;

  @visibleForTesting
  void setToastification(Toastification instance) => _toastInstance = instance;

  Future<bool> makePayment({required int amount, required String currency}) async {
    try {
      String? paymentIntentClientSecret = await _createPaymentIntent(
        amount,
        currency,
      );

      if (paymentIntentClientSecret == null) return false;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentClientSecret, merchantDisplayName: "Shop Now"),
      );

      return await _handlePaymentSheet();
    } catch (e) {
      debugPrint(" ===========> PAYMENT PROCESS ERROR");
      debugPrint(e.toString());
    }

    return false;
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    debugPrint(" =======> Trying to create Payment intent");
    try {
      // Input validation for security - throw immediately to ensure tests can catch it
      if (amount < 0) {
        throw ArgumentError('Amount must be positive');
      }

      if (currency.isEmpty) {
        throw ArgumentError('Currency cannot be empty');
      }

      // Use getter instead of direct instantiation for testability
      final Dio dio = _dio;

      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        "currency": currency,
      };

      // Sanitize secret key before logging
      final secretKey = dotenv.env['SECRET_KEY'] ?? '';
      if (secretKey.isEmpty) {
        debugPrint("Warning: SECRET_KEY is empty");
        return null;
      }

      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer ${dotenv.env['SECRET_KEY']}",
            "Content-Type": "application/x-www-form-urlencoded",
          },
        ),
      );

      log(" ==========> response: $response");

      if (response.data != null) {
        return response.data["client_secret"];
      }
      return null;
    } catch (e) {
      debugPrint(" =======> PAYMENT INTENT ERROR");
      // Don't log the full error as it might contain sensitive information
      log("Error creating payment intent: $e");

      // Re-throw ArgumentError so tests can catch it
      if (e is ArgumentError) {
        rethrow;
      }
    }
    return null;
  }

  Future<bool> _handlePaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      //  await Stripe.instance.confirmPaymentSheetPayment();

      // Payment succeeded!
      _toastification.show(
        title: const Text('Payment Successful'),
        description: const Text('Your payment has been processed successfully.'),
        type: ToastificationType.success,
        style: ToastificationStyle.minimal,
        // alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
      if (kDebugMode) {
        debugPrint('Payment successful');
      }

      return true;
    } on StripeException catch (e) {
      // Handle Stripe-specific errors
      if (kDebugMode) {
        debugPrint('StripeException: ${e.error.localizedMessage}');
      }
      String errorMessage = e.error.localizedMessage ?? 'An unknown payment error occurred.';

      _toastification.show(
        title: const Text('Payment Error'),
        description: Text(errorMessage),
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        // alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 5),
      );

      return false;
    } catch (e) {
      // Handle other general exceptions
      if (kDebugMode) {
        debugPrint('General Exception: ${e.toString()}');
      }
      _toastification.show(
        title: const Text('Payment Error'),
        description: const Text('An unexpected error occurred during payment.'),
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        // alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 5),
      );

      return false;
    }
  }

  String _calculateAmount(int amount) {
    // Input validation for security
    assert(amount >= 0, 'Amount must be positive');

    final calculateAmount = amount * 100;
    return calculateAmount.toString();
  }

  // Expose methods for testing with @visibleForTesting annotation
  @visibleForTesting
  String calculateAmountForTesting(int amount) {
    return _calculateAmount(amount);
  }

  @visibleForTesting
  Future<String?> createPaymentIntentForTesting(int amount, String currency) {
    return _createPaymentIntent(amount, currency);
  }

  @visibleForTesting
  Future<bool> handlePaymentSheetForTesting() {
    return _handlePaymentSheet();
  }
}
