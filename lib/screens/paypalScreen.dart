// PAYPAL PAYMENT SCREEN
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/services/paypal_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      Get.back();
      return;
    }

    final payment = await _payPalService.createPaypalPayment(
        accessToken, widget.amount, widget.currency, widget.description);

    if (payment == null) {
      widget.onFinish(false);
      Get.back();
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
                Get.back();
              }
              return NavigationDecision.prevent;
            }

            if (request.url.startsWith(PayPalConfig.cancelURL)) {
              widget.onFinish(false);
              Get.back();
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
      Get.back();
      return;
    }

    final success = await _payPalService.executePayment(accessToken, _paymentId!, payerId);

    widget.onFinish(success);
    Get.back();
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
            Get.back();
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
