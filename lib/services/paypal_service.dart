import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Replace http with dio
import 'package:webview_flutter/webview_flutter.dart';

class PayPalConfig {
  static const String clientId =
      "AT5pgO3wqDekInrqwNz5KiATQsaeK_eiZOk2izbhfMFQwxinP0h5od-YGyujsoDg9-3O36_SjYoC5In_";
  static const String secret =
      "EN42fygZUdYXN4KErEMC5NdAuNyV_IQFdC8poee9MqpAoheC_SdQ9UpaSHkjpUYmlxSpUP7g8PPpxVA5";
  static const String returnURL = "ahop_now_mobile://paypalpay";
  static const String cancelURL = "ahop_now_mobile://cancel";

  // Change to false when deploying to production
  static const bool sandbox = true;

  static String get baseUrl {
    return sandbox ? "https://api.sandbox.paypal.com" : "https://api.paypal.com";
  }
}

class PayPalService {
  final Dio _dio = Dio(); // Create Dio instance

  // Get access token from PayPal
  Future<String?> getAccessToken() async {
    try {
      final auth = base64.encode(utf8.encode("${PayPalConfig.clientId}:${PayPalConfig.secret}"));

      final response = await _dio.post("${PayPalConfig.baseUrl}/v1/oauth2/token",
          options: Options(
            contentType: "application/x-www-form-urlencoded",
            headers: {"Authorization": "Basic $auth"},
          ),
          data: "grant_type=client_credentials");

      return response.data["access_token"];
    } catch (e) {
      debugPrint("Error getting PayPal access token: $e");
      return null;
    }
  }

  // Create PayPal payment
  Future<Map<String, String>?> createPaypalPayment(
      String accessToken, double amount, String currency, String description) async {
    try {
      final Map<String, dynamic> body = {
        "intent": "sale",
        "payer": {"payment_method": "paypal"},
        "transactions": [
          {
            "amount": {"total": amount.toStringAsFixed(2), "currency": currency},
            "description": description
          }
        ],
        "redirect_urls": {
          "return_url": PayPalConfig.returnURL,
          "cancel_url": PayPalConfig.cancelURL
        }
      };

      final response = await _dio.post("${PayPalConfig.baseUrl}/v1/payments/payment",
          options: Options(
            contentType: "application/json",
            headers: {"Authorization": "Bearer $accessToken"},
          ),
          data: body);

      if (response.statusCode == 201) {
        final links = response.data["links"] as List;
        String? approvalUrl;
        String? executeUrl;
        String? paymentId = response.data["id"];

        for (final link in links) {
          if (link["rel"] == "approval_url") {
            approvalUrl = link["href"];
          } else if (link["rel"] == "execute") {
            executeUrl = link["href"];
          }
        }

        return {
          "approvalUrl": approvalUrl ?? "",
          "executeUrl": executeUrl ?? "",
          "paymentId": paymentId ?? ""
        };
      }
      return null;
    } catch (e) {
      debugPrint("Error creating PayPal payment: $e");
      return null;
    }
  }

  // Execute payment after user approval
  Future<bool> executePayment(String accessToken, String paymentId, String payerId) async {
    try {
      final response =
          await _dio.post("${PayPalConfig.baseUrl}/v1/payments/payment/$paymentId/execute",
              options: Options(
                contentType: "application/json",
                headers: {"Authorization": "Bearer $accessToken"},
              ),
              data: {"payer_id": payerId});

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error executing PayPal payment: $e");
      return false;
    }
  }
}

class PayPalPaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final String description;
  final Function(bool) onFinish;

  const PayPalPaymentScreen({
    super.key,
    required this.amount,
    required this.currency,
    required this.description,
    required this.onFinish,
  });

  @override
  _PayPalPaymentScreenState createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  final PayPalService _payPalService = PayPalService();
  bool _isLoading = true;
  String? _approvalUrl;
  String? _executeUrl;
  String? _paymentId;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    final accessToken = await _payPalService.getAccessToken();
    if (accessToken == null) {
      widget.onFinish(false);
      Navigator.of(context).pop();
      return;
    }

    final payment = await _payPalService.createPaypalPayment(
        accessToken, widget.amount, widget.currency, widget.description);

    if (payment == null) {
      widget.onFinish(false);
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _approvalUrl = payment["approvalUrl"];
      _executeUrl = payment["executeUrl"];
      _paymentId = payment["paymentId"];
      _isLoading = false;
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(PayPalConfig.returnURL)) {
              final uri = Uri.parse(request.url);
              final payerId = uri.queryParameters['PayerID'];

              if (payerId != null && _paymentId != null) {
                _completePayment(payerId);
              } else {
                widget.onFinish(false);
                Navigator.of(context).pop();
              }
              return NavigationDecision.prevent;
            }

            if (request.url.startsWith(PayPalConfig.cancelURL)) {
              widget.onFinish(false);
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_approvalUrl!));
  }

  Future<void> _completePayment(String payerId) async {
    final accessToken = await _payPalService.getAccessToken();
    if (accessToken == null) {
      widget.onFinish(false);
      Navigator.of(context).pop();
      return;
    }

    final success = await _payPalService.executePayment(accessToken, _paymentId!, payerId);

    widget.onFinish(success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onFinish(false);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _approvalUrl != null
              ? WebViewWidget(controller: _webViewController!)
              : const Center(child: Text('Failed to load payment page')),
    );
  }
}
