// lib/screens/category_products_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:shop_now_mobile/widgets/custom_nav_bar.dart';
import 'package:shop_now_mobile/widgets/searchBar.dart';

class DessertScreen extends StatefulWidget {
  static const routeName = '/dessertScreen';
  const DessertScreen({super.key});

  @override
  State<DessertScreen> createState() => _DessertScreenState();
}

class _DessertScreenState extends State<DessertScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  late final String? categoryId;
  late final String? categoryName;
  late final String? brandId;
  late final String? brandName;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    categoryId = args?['categoryId'] as String?;
    categoryName = args?['categoryName'] as String?;
    brandId = args?['brandId'] as String?;
    brandName = args?['brandName'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final title =
        (brandName ?? categoryName) != null ? '${brandName ?? categoryName} products' : 'Products';
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, title),
                const SizedBox(height: 10),
                SearchBarCustom(
                  title: 'Search products',
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchTerm = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildProductsList()),
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomNavBar(menu: false),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.greyDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: Helper.getTheme(context).headlineLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    Query productsQuery = _firestore.collection('products');
    if (categoryId != null) {
      productsQuery = productsQuery.where('categoryRef',
          isEqualTo: FirebaseFirestore.instance.doc(
            "/categories/$categoryId",
          ));
    }
    if (brandId != null) {
      productsQuery = productsQuery.where('brandRef',
          isEqualTo: FirebaseFirestore.instance.doc(
            "/brands/$brandId",
          ));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: productsQuery.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).where((p) {
          final name = (p['name'] as String).toLowerCase();
          return _searchTerm.isEmpty || name.contains(_searchTerm);
        }).toList();
        if (docs.isEmpty) {
          return const Center(child: Text('No products found'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final prod = docs[index];
            return _buildProductCard(prod);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final imageUrl = p['imageUrl'] as String?;
    final name = p['name'] as String;
    final price = p['price'] as num;
    return InkWell(
      onTap: () => Get.toNamed(
        AppPageNames.individualItemScreen,
        arguments: {
          'productId': p['id'],
        },
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover)
                    : Container(color: AppColors.placeholderBg),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('£${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.primaryMaterialColor,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
