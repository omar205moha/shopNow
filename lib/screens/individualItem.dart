import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/controllers/main_cart_controller.dart';
import 'package:shop_now_mobile/models/product.dart';
import 'package:shop_now_mobile/utils/helper.dart';

class IndividualItem extends StatefulWidget {
  static const routeName = "/individualScreen";

  const IndividualItem({super.key});

  @override
  State<IndividualItem> createState() => _IndividualItemState();
}

class _IndividualItemState extends State<IndividualItem> {
  int quantity = 1;
  late String productId;
  late Stream<DocumentSnapshot> productStream;
  final MainCartController cartController = Get.find<MainCartController>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    productId = args['productId'];
    productStream = FirebaseFirestore.instance.collection('products').doc(productId).snapshots();
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: productStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Product not found'));
          }

          final productData = snapshot.data!.data() as Map<String, dynamic>;
          final product = Product.fromMap({...productData, 'id': productId});

          return _buildProductView(context, product);
        },
      ),
    );
  }

  Widget _buildProductView(BuildContext context, Product product) {
    final double totalPrice = product.price * quantity;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildImageSection(context, product),
            ),
            SliverToBoxAdapter(
              child: _buildDetailsSection(context, product),
            ),
            // Add padding at the bottom to ensure content isn't hidden behind the add to cart section
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildAddToCartSection(context, product, totalPrice),
        ),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context, Product product) {
    return Stack(
      children: [
        SizedBox(
          height: Helper.getScreenHeight(context) * 0.45,
          width: Helper.getScreenWidth(context),
          child: product.imageUrl.isNotEmpty
              ? Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      Helper.getAssetName("placeholder.jpg", "real"),
                      fit: BoxFit.cover,
                    );
                  },
                )
              : Container(
                  color: AppColors.placeholder,
                ),
        ),
        Container(
          height: Helper.getScreenHeight(context) * 0.45,
          width: Helper.getScreenWidth(context),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4],
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.0),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                  ),
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
                          Helper.getAssetName("cart_white.png", "virtual"),
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
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, Product product) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              product.name,
              style: Helper.getTheme(context).headlineLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Brand: ${product.brandName}',
                        style: const TextStyle(
                          color: AppColors.greyDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Category: ${product.categoryName}',
                        style: const TextStyle(
                          color: AppColors.greyDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Unit: ${product.unit}',
                        style: const TextStyle(
                          color: AppColors.greyDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPrice(product),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDescription(context, product),
          const SizedBox(height: 20),
          _buildQuantitySelector(product),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: AppColors.placeholder,
              thickness: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quantity",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Available: ${product.stock}",
                style: TextStyle(
                  fontSize: 14,
                  color: product.stock > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: _decrementQuantity,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: AppColors.placeholder.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.remove),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.placeholder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  quantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: _incrementQuantity,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: AppColors.orangeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrice(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 20),
        Text(
          "£${product.price.toStringAsFixed(2)}",
          style: const TextStyle(
            color: AppColors.greyDark,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (product.originalPrice > product.price)
          Text(
            "£${product.originalPrice.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Description",
            style: Helper.getTheme(context).headlineMedium?.copyWith(
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 10),
          Text(product.description),
        ],
      ),
    );
  }

  Widget _buildAddToCartSection(BuildContext context, Product product, double totalPrice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Total Price",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Text(
                  "£${totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: AppColors.greyDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: product.stock > 0
                  ? () {
                      cartController.addToCart(product, quantity);
                      Get.snackbar(
                        'Added to Cart',
                        '${product.name} added to your cart',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: AppColors.orangeColor.withOpacity(0.8),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: product.stock > 0 ? AppColors.orangeColor : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    product.stock > 0 ? "Add to Cart" : "Out of Stock",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
