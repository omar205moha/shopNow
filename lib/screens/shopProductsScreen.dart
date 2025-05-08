import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/models/product.dart';

class ShopProductsScreen extends StatelessWidget {
  static const routeName = '/shopProductsScreen';
  const ShopProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final shopId = args['shopId'] as String;
    final shopName = args['shopName'] as String;

    final shopRef = FirebaseFirestore.instance.doc('/shops/$shopId');

    return Scaffold(
      appBar: AppBar(
        title: Text(shopName),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('shopRef', isEqualTo: shopRef)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error: \${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(
                child: CupertinoActivityIndicator(
              color: AppColors.primaryMaterialColor,
            ));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No products for this shop'));
          }
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final product = Product.fromMap(doc.data());
                final hasDiscount = product.price < product.originalPrice;
                return InkWell(
                  onTap: () => Get.toNamed(
                    AppPageNames.individualItemScreen,
                    arguments: {
                      'productId': product.id,
                    },
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                  borderRadius:
                                      const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: product.imageUrl.isNotEmpty
                                      ? Image.network(product.imageUrl,
                                          width: double.infinity, fit: BoxFit.cover)
                                      : Container(color: AppColors.placeholderBg)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Stock: ${product.stock} ${product.unit}',
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('£${product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryMaterialColor)),
                                      if (hasDiscount) ...[
                                        const SizedBox(width: 6),
                                        Text('£${product.originalPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                decoration: TextDecoration.lineThrough,
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (product.featured)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppColors.primaryMaterialColor,
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text('Featured',
                                  style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
