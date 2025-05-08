import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/controllers/main_cart_controller.dart';
import 'package:shop_now_mobile/screens/checkoutScreen.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:shop_now_mobile/widgets/custom_nav_bar.dart';

class MyOrderScreen extends StatefulWidget {
  static const routeName = "/myOrderScreen";

  const MyOrderScreen({super.key});

  @override
  State<MyOrderScreen> createState() => _MyOrderScreenState();
}

class _MyOrderScreenState extends State<MyOrderScreen> {
  final MainCartController _cartController = Get.find<MainCartController>();
  String _deliveryNote = "";
  bool _isAddingNote = false;
  final TextEditingController _noteController = TextEditingController();

  double get _deliveryCost => 2.0;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleAddNote() {
    setState(() {
      _isAddingNote = !_isAddingNote;
      if (_isAddingNote) {
        _noteController.text = _deliveryNote;
      }
    });
  }

  void _saveNote() {
    setState(() {
      _deliveryNote = _noteController.text;
      _isAddingNote = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Obx(() {
                if (_cartController.cartItems.isEmpty) {
                  return _buildEmptyCart(context);
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      /*   const SizedBox(height: 20),
                    _buildStoreInfo(context),
                    const SizedBox(height: 30),*/
                      _buildOrderItems(),
                      _buildOrderSummary(context),
                      // Add extra space for bottom navigation bar
                      const SizedBox(height: 70),
                    ],
                  ),
                );
              }),
            ),
            /*   const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomNavBar(),
          ),*/
          ],
        ),
        bottomSheet: Obx(() {
          if (_cartController.cartItems.isEmpty) return const SizedBox.shrink();

          return IntrinsicHeight(
            child:
                Container(margin: const EdgeInsets.all(10), child: _buildCheckoutButton(context)),
          );
        }));
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_rounded),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "My Cart",
              style: Helper.getTheme(context).headlineLarge,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Get.defaultDialog(
                title: "Clear Cart",
                middleText: "Are you sure you want to remove all items from your cart?",
                textConfirm: "Clear",
                textCancel: "Cancel",
                confirmTextColor: Colors.white,
                buttonColor: AppColors.orangeColor,
                onConfirm: () {
                  _cartController.clearCart();
                  Get.back();
                },
              );
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreImage(),
          const SizedBox(width: 15),
          Expanded(child: _buildStoreDetails(context)),
        ],
      ),
    );
  }

  Widget _buildStoreImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 80,
        width: 80,
        child: Image.asset(
          Helper.getAssetName("store_icon.jpg", "real"),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.placeholderBg,
              child: const Icon(
                Icons.storefront,
                size: 40,
                color: AppColors.orangeColor,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoreDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Shop Now",
          style: Helper.getTheme(context).headlineSmall,
        ),
        const SizedBox(height: 5),
        _buildRatingRow(),
        const SizedBox(height: 5),
        _buildCategoryRow(),
        const SizedBox(height: 5),
        _buildAddressRow(),
      ],
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        Image.asset(
          Helper.getAssetName("star_filled.png", "virtual"),
          height: 18,
        ),
        const SizedBox(width: 5),
        const Text(
          "4.8",
          style: TextStyle(
            color: AppColors.orangeColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Text(" (230 ratings)"),
      ],
    );
  }

  Widget _buildCategoryRow() {
    return const Row(
      children: [
        Text("Marketplace"),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            "•",
            style: TextStyle(
              color: AppColors.orangeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text("Various Products"),
      ],
    );
  }

  Widget _buildAddressRow() {
    return Row(
      children: [
        SizedBox(
          height: 15,
          child: Image.asset(
            Helper.getAssetName("loc.png", "virtual"),
          ),
        ),
        const SizedBox(width: 5),
        const Expanded(
          child: Text(
            "17 Queen Street, Cardiff, CF10 2HQ",
            style: TextStyle(fontSize: 12.0),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        )
      ],
    );
  }

  Widget _buildOrderItems() {
    return Container(
      width: double.infinity,
      color: AppColors.placeholderBg,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Column(
        children: [
          for (int i = 0; i < _cartController.cartItems.length; i++)
            CartItemCard(
              cartItem: _cartController.cartItems[i],
              onIncrease: () => _cartController.updateQuantity(
                _cartController.cartItems[i].product.id,
                _cartController.cartItems[i].quantity + 1,
              ),
              onDecrease: () => _cartController.updateQuantity(
                _cartController.cartItems[i].product.id,
                _cartController.cartItems[i].quantity - 1,
              ),
              onRemove: () => _cartController.removeFromCart(
                _cartController.cartItems[i].product.id,
              ),
              isLast: i == _cartController.cartItems.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildDeliveryInstructions(context),
          if (_isAddingNote) _buildNoteInput(),
          if (_deliveryNote.isNotEmpty && !_isAddingNote) _buildNoteDisplay(),
          const SizedBox(height: 15),
          _buildPriceDetail(
              context, "Sub Total", "£${_cartController.totalPrice.toStringAsFixed(2)}"),
          const SizedBox(height: 10),
          _buildPriceDetail(context, "Delivery Cost", "£${_deliveryCost.toStringAsFixed(2)}"),
          const SizedBox(height: 10),
          Divider(
            color: AppColors.placeholder.withOpacity(0.25),
            thickness: 1.5,
          ),
          const SizedBox(height: 10),
          _buildPriceDetail(
            context,
            "Total",
            "£${(_cartController.totalPrice + _deliveryCost).toStringAsFixed(2)}",
            isTotal: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDeliveryInstructions(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.placeholder.withOpacity(0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Delivery Instruction",
              style: Helper.getTheme(context).headlineSmall,
            ),
          ),
          TextButton(
            onPressed: _toggleAddNote,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
            ),
            child: Row(
              children: [
                Icon(
                  _isAddingNote || _deliveryNote.isNotEmpty ? Icons.edit : Icons.add,
                  color: AppColors.orangeColor,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Text(
                  _isAddingNote || _deliveryNote.isNotEmpty ? "Edit Notes" : "Add Notes",
                  style: const TextStyle(
                    color: AppColors.orangeColor,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: "Enter delivery instructions here",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isAddingNote = false;
                  });
                },
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeColor,
                ),
                child: const Text(
                  "Save Note",
                  style: TextStyle(color: AppColors.whiteColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteDisplay() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.placeholderBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _deliveryNote,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildPriceDetail(BuildContext context, String title, String amount,
      {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Helper.getTheme(context).headlineSmall,
          ),
        ),
        Text(
          amount,
          style: Helper.getTheme(context).headlineSmall?.copyWith(
                color: AppColors.orangeColor,
                fontSize: isTotal ? 22 : null,
              ),
        )
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _cartController.cartItems.isEmpty
            ? null // Disable button if cart is empty
            : () {
                Navigator.of(context).pushNamed(
                  CheckoutScreen.routeName,
                  arguments: {
                    'subtotal': _cartController.totalPrice,
                    'deliveryCost': _deliveryCost,
                    'total': _cartController.totalPrice + _deliveryCost,
                    'deliveryNote': _deliveryNote,
                  },
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orangeColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: AppColors.placeholderBg,
        ),
        child: Text(
          "Checkout",
          style: Helper.getTheme(context).bodyMedium?.copyWith(
                color: AppColors.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final bool isLast;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.cartItem,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: AppColors.placeholder.withOpacity(0.25),
                ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: cartItem.product.imageUrl.isNotEmpty
                      ? Image.network(
                          cartItem.product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.placeholderBg,
                              //  child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.placeholderBg,
                          //  child: const Icon(Icons.image_not_supported),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cartItem.product.name,
                      style: const TextStyle(
                        color: AppColors.greyDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${cartItem.product.brandName} · ${cartItem.product.unit}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "£${cartItem.product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: AppColors.orangeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Remove button
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.placeholder),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onDecrease,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cartItem.quantity > 1
                              ? AppColors.orangeColor.withOpacity(0.1)
                              : Colors.grey.shade200,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: cartItem.quantity > 1 ? AppColors.orangeColor : Colors.grey,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Text(
                        cartItem.quantity.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: cartItem.quantity < cartItem.product.stock ? onIncrease : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cartItem.quantity < cartItem.product.stock
                              ? AppColors.orangeColor.withOpacity(0.1)
                              : Colors.grey.shade200,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: cartItem.quantity < cartItem.product.stock
                              ? AppColors.orangeColor
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Item total price
              Text(
                "£${cartItem.totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: AppColors.greyDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
