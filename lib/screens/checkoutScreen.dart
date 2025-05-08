import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/controllers/main_cart_controller.dart';
import 'package:shop_now_mobile/screens/homeScreen.dart';
import 'package:shop_now_mobile/screens/myOrdersScreen.dart';
import 'package:shop_now_mobile/screens/orderTrackingScreen.dart';
import 'package:shop_now_mobile/services/payment_service.dart';
import 'package:shop_now_mobile/utils/constant.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:shop_now_mobile/widgets/location_picker_form_field.dart';

enum PaymentMethod { cashOnDelivery, creditCard, paypal }

// CHECKOUT SCREEN
class CheckoutScreen extends StatefulWidget {
  static const routeName = "/checkoutScreen";

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPaying = false;
  String _selectedLocationAddress = "";
  GeoPoint? _selectedLocation;
  final addressController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cashOnDelivery;

  // GetX Controllers
  final MainCartController cartController = Get.find<MainCartController>();

  @override
  void initState() {
    super.initState();
    //  final userAddress = GetStorage().read(PrefKey.userAddress.name);
//
    //  setState(() {
    //    addressController.text = userAddress ?? '';
    //  });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            SafeArea(child: Obx(() {
              if (cartController.cartItems.isEmpty) {
                return _buildEmptyCart(context);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildDeliveryAddressSection(),
                            _buildPaymentMethodSection(),
                            _buildCartItemsList(),
                            _buildOrderSummary(),

                            const SizedBox(height: 80), // Space for nav bar
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            })),
            /*  const Positioned(
            bottom: 0,
            left: 0,
            child: CustomNavBar(),
          ),*/
          ],
        ),
        bottomSheet: Obx(() {
          if (cartController.cartItems.isEmpty) return const SizedBox.shrink();

          return IntrinsicHeight(
            child: _buildCheckoutButton(),
          );
        }));
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_rounded),
          ),
          Expanded(
            child: Text(
              "Checkout",
              style: Helper.getTheme(context).headlineLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_empty,
            size: 50,
          ),
          const SizedBox(height: 20),
          Text(
            "Your Cart is Empty",
            style: Helper.getTheme(context).headlineMedium,
          ),
          const SizedBox(height: 10),
          const Text(
            "Looks like you haven't added any items to your cart yet",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () {
                Get.back(); // Navigate back to continue shopping
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Start Shopping",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Delivery Address",
            style: Helper.getTheme(context).titleLarge,
          ),
          const SizedBox(height: 15),
          LocationPickerInput(
            controller: addressController,
            onLocationSelected: (location) {
              setState(() {
                _selectedLocationAddress = location.address;
                _selectedLocation = GeoPoint(location.lat, location.lng);
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please select your delivery location";
              }

              return null;
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Method",
            style: Helper.getTheme(context).titleLarge,
          ),
          const SizedBox(height: 15),
          _buildPaymentOption(
            PaymentMethod.cashOnDelivery,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Cash on delivery"),
                _buildSelectionCircle(PaymentMethod.cashOnDelivery),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            PaymentMethod.creditCard,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Image.asset(
                        Helper.getAssetName("visa2.png", "real"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text("Credit Card"),
                  ],
                ),
                _buildSelectionCircle(PaymentMethod.creditCard),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            PaymentMethod.paypal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 30,
                      child: Image.asset(
                        Helper.getAssetName("paypal.png", "real"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text("PayPal"),
                  ],
                ),
                _buildSelectionCircle(PaymentMethod.paypal),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSelectionCircle(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method;
    return Container(
      width: 18,
      height: 18,
      decoration: ShapeDecoration(
        shape: CircleBorder(
          side: BorderSide(
            color: isSelected ? AppColors.orangeColor : AppColors.placeholder.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const ShapeDecoration(
                  color: AppColors.orangeColor,
                  shape: CircleBorder(),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPaymentOption(PaymentMethod method, {required Widget child}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        height: 60,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: _selectedPaymentMethod == method
                  ? AppColors.orangeColor
                  : AppColors.placeholder.withOpacity(0.25),
              width: _selectedPaymentMethod == method ? 2 : 1,
            ),
          ),
          color: _selectedPaymentMethod == method
              ? AppColors.orangeColor.withOpacity(0.1)
              : AppColors.placeholderBg,
        ),
        child: child,
      ),
    );
  }

  Widget _buildCartItemsList() {
    return Obx(() {
      final items = cartController.cartItems;

      if (items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text("Your cart is empty"),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Items",
              style: Helper.getTheme(context).titleLarge,
            ),
            const SizedBox(height: 15),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length > 3 ? 3 : items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: item.product.imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(item.product.imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: AppColors.placeholder),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: Helper.getTheme(context).titleMedium,
                          ),
                          Text(
                            "${item.quantity} x £${item.product.price.toStringAsFixed(2)}",
                            style: Helper.getTheme(context).bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "£${(item.product.price * item.quantity).toStringAsFixed(2)}",
                      style: Helper.getTheme(context).titleMedium,
                    ),
                  ],
                );
              },
            ),
            if (items.length > 3)
              TextButton(
                onPressed: () {
                  // Show all items in a modal bottom sheet or navigate to cart screen
                },
                child: Text(
                  "View all ${items.length} items",
                  style: const TextStyle(
                    color: AppColors.orangeColor,
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      );
    });
  }

  Widget _buildOrderSummary() {
    return Obx(() {
      final subTotal = cartController.totalPrice;
      const deliveryCost = 2.0;
      final total = subTotal + deliveryCost;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Summary",
              style: Helper.getTheme(context).titleLarge,
            ),
            const SizedBox(height: 15),
            _buildSummaryRow("Sub Total", "£${subTotal.toStringAsFixed(2)}"),
            const SizedBox(height: 10),
            _buildSummaryRow("Delivery Cost", "£${deliveryCost.toStringAsFixed(2)}"),
            //  const SizedBox(height: 10),
            //  _buildSummaryRow("Discount", "-£${discount.toStringAsFixed(2)}"),
            Divider(
              height: 40,
              color: AppColors.placeholder.withOpacity(0.25),
              thickness: 2,
            ),
            _buildSummaryRow("Total", "£${total.toStringAsFixed(2)}", isTotal: true),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final valueStyle = isTotal
        ? Helper.getTheme(context).headlineSmall?.copyWith(
              color: AppColors.orangeColor,
              fontWeight: FontWeight.bold,
            )
        : Helper.getTheme(context).bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isPaying ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaterialColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isPaying
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(
                      color: Colors.white,
                      radius: 10,
                    ),
                    SizedBox(width: 10),
                    Text("Processing..."),
                  ],
                )
              : const Text(
                  "Place Order",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      // Show snackbar with error message
      Get.snackbar(
        "Error",
        "Please fill all required fields",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isPaying = true;
    });

    try {
      final paymentService = PaymentService();
      bool paymentSuccess = false;

      switch (_selectedPaymentMethod) {
        case PaymentMethod.cashOnDelivery:
          // Just simulate processing for cash on delivery
          await Future.delayed(const Duration(seconds: 1));
          paymentSuccess = true;
          break;
        case PaymentMethod.creditCard:
          paymentSuccess =
              await paymentService.processCardPayment(cartController.totalPrice.ceil() + 2);
          break;
        case PaymentMethod.paypal:
          paymentSuccess =
              await paymentService.processPayPalPayment(context, cartController.totalPrice + 2);
          break;
      }

      if (paymentSuccess) {
        // Create order with the cart items and delivery information
        await _createOrder();
        _showSuccessPaymentBottomSheet();
      } else {
        _showPaymentErrorDialog();
      }
    } catch (e) {
      log(" ==============> Process payment error: $e");
      _showPaymentErrorDialog();
    } finally {
      setState(() {
        if (mounted) _isPaying = false;
      });
    }
  }

  Future<bool> _createOrder() async {
    try {
      // // Show loading indicator
      // Get.dialog(
      //   const Center(child: CircularProgressIndicator()),
      //   barrierDismissible: false,
      // );

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.back(); // Close loading dialog
        Get.snackbar('Error', 'You must be logged in to place an order');
        return false;
      }

      // Format items according to the schema
      final formattedItems = cartController.cartItems.asMap().entries.map((entry) {
        final item = entry.value;

        return {
          'name': item.product.name,
          'price': item.product.price,
          'productRef': FirebaseFirestore.instance.collection("products").doc(item.product.id),
          'quantity': item.quantity,
          'unit': item.product.unit,
          'shopRef': FirebaseFirestore.instance.collection("shops").doc(item.product.shopRef.id),
          'total': item.product.price * item.quantity,
        };
      }).toList();

      // Save to Firestore
      final orderDoc = FirebaseFirestore.instance.collection('orders').doc();

      // Create order document based on schema
      final orderData = {
        'acceptedAt': null,
        'requestedAt': FieldValue.serverTimestamp(),
        'buyerRef': FirebaseFirestore.instance.collection("users").doc(user.uid),
        'deliveredAt': null,
        'deliveryAddress': _selectedLocationAddress,
        'deliveryLocation': _selectedLocation,
        'distanceText': null,
        'geohashDelivery': null,
        'geohashStore': null,
        'id': orderDoc.id,
        'items': formattedItems,
        'shopRefs': formattedItems.map((item) => item['shopRef']).toList(),
        'pickedUpAt': null,
        'status': 'pending',
        'total': cartController.totalPrice,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await orderDoc.set(orderData);

      // Update product stock
      for (var item in cartController.cartItems) {
        final productRef = FirebaseFirestore.instance.collection('products').doc(item.product.id);

        // Use transaction to safely update stock
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final productDoc = await transaction.get(productRef);
          if (!productDoc.exists) {
            throw Exception('Product does not exist!');
          }

          final currentStock = productDoc.data()?['stock'] ?? 0;
          if (currentStock < item.quantity) {
            throw Exception('Not enough stock for ${item.product.name}');
          }

          transaction.update(productRef, {
            'stock': currentStock - item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      }

      // Clear cart after successful order
      cartController.clearCart();

      // Close loading dialog
      Get.back();

      // Show success message
      Get.snackbar(
        'Success',
        'Your order has been placed successfully!',
        backgroundColor: AppColors.primaryMaterialColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate to order confirmation page
      Get.toNamed(AppPageNames.homeScreen);

      return true;
    } catch (error) {
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to place order: ${error.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      log('==========> Order creation error: $error');
      return false;
    }
  }

  void _showPaymentErrorDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Payment Failed"),
        content: const Text(
          "There was an error processing your payment. Please try again or choose a different payment method.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSuccessPaymentBottomSheet() {
    Get.bottomSheet(
      backgroundColor: AppColors.backgroundColor,
      const SuccessPaymentBottomSheet(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      isDismissible: false,
    );
  }
}

class SuccessPaymentBottomSheet extends StatelessWidget {
  const SuccessPaymentBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCloseButton(),
          _buildSuccessImage(),
          const SizedBox(height: 20),
          _buildThankYouText(context),
          const SizedBox(height: 20),
          _buildInfoText(),
          const SizedBox(height: 30),
          _buildTrackOrderButton(),
          _buildBackToHomeButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.clear),
        ),
      ],
    );
  }

  Widget _buildSuccessImage() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.orangeColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.check_circle,
          color: AppColors.orangeColor,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildThankYouText(BuildContext context) {
    return Text(
      "Thank You!",
      style: Helper.getTheme(context).headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildInfoText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        "Your order has been placed successfully. You can track the delivery in the 'Track Order' section.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.placeholder,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTrackOrderButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Get.offNamed(MyOrdersScreen.routeName);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orangeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Track Order",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToHomeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            Get.offAllNamed(HomeScreen.routeName);
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.orangeColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.orangeColor),
            ),
          ),
          child: const Text(
            "Back to Home",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
