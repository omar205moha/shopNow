import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/controllers/main_cart_controller.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:shop_now_mobile/widgets/custom_nav_bar.dart';

class OfferScreen extends StatelessWidget {
  static const routeName = "/offerScreen";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DocumentReference? shopRef; 

  final MainCartController cartController = Get.find<MainCartController>();

  OfferScreen({super.key, this.shopRef});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: Helper.getScreenHeight(context),
          width: Helper.getScreenWidth(context),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Latest Offers",
                      style: Helper.getTheme(context).headlineLarge,
                    ),
                    InkWell(
                      onTap: () {
                        Get.toNamed(AppPageNames.myOrderScreen);
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Image.asset(
                              Helper.getAssetName("cart.png", "virtual"),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Obx(() => cartController.cartItems.isNotEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.orangeColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${cartController.cartItems.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : const SizedBox()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Display discounted products
              Expanded(
                child: _buildDiscountedProductsGrid(),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: const IntrinsicHeight(
        child: Positioned(
          bottom: 0,
          left: 0,
          child: CustomNavBar(
            offer: true,
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountedProductsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("products")
          //  .where("shopRef", isEqualTo: shopRef)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _emptyState('Error loading offers');
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState('No products found');
        }

        // Filter for discounted or featured products
        final discountedDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final hasDiscount = (data['price'] ?? 0) < (data['originalPrice'] ?? 0);
          final isFeatured = data['featured'] == true;
          return hasDiscount || isFeatured;
        }).toList();

        if (discountedDocs.isEmpty) {
          return _emptyState('No offers available at the moment');
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: .7,
          ),
          itemCount: discountedDocs.length,
          itemBuilder: (_, i) {
            final data = discountedDocs[i].data() as Map<String, dynamic>;
            return _productCard(discountedDocs[i].id, data, context);
          },
        );
      },
    );
  }

  Widget _productCard(String id, Map<String, dynamic> p, BuildContext context) {
    final hasDiscount = (p['price'] ?? 0) < (p['originalPrice'] ?? 0);
    final inStock = (p['stock'] ?? 0) > 0;
    final isFeatured = p['featured'] == true;

    return Card(
      elevation: 5,
      shadowColor: Colors.white10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .pushNamed(AppPageNames.individualItemScreen, arguments: {"productId": p['id']});
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with badges
              Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                              p['imageUrl'],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.error_outline, size: 40),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image, size: 50, color: Colors.grey),
                              ),
                            ),
                    ),
                  ),

                  // Discount badge
                  if (hasDiscount)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          '${(((p['originalPrice'] - p['price']) / p['originalPrice']) * 100).round()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  // Featured badge
                  if (isFeatured)
                    Positioned(
                      top: hasDiscount ? 30 : 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber[800],
                          borderRadius: BorderRadius.only(
                            topLeft: hasDiscount ? Radius.zero : const Radius.circular(10),
                            bottomRight: const Radius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  // Stock label
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: inStock ? Colors.green : Colors.red,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        inStock ? 'In Stock' : 'Out of Stock',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p['name'] ?? 'Unnamed Product',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Stock: ${p['stock'] ?? 0}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "£${p['price']?.toStringAsFixed(2) ?? '0.00'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryMaterialColor,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            "£${p['originalPrice']?.toStringAsFixed(2) ?? '0.00'}",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
