// lib/screens/menu_screen.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/controllers/main_cart_controller.dart';
import 'package:shop_now_mobile/screens/checkoutScreen.dart';
import 'package:shop_now_mobile/screens/dessertScreen.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:shop_now_mobile/widgets/custom_nav_bar.dart';
import 'package:shop_now_mobile/widgets/searchBar.dart';

class MenuScreen extends StatefulWidget {
  static const routeName = '/menuScreen';
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _searchTerm = '';
  final MainCartController cartController = Get.find<MainCartController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                SearchBarCustom(
                  title: 'Search categories',
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchTerm = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildCategoriesList()),
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomNavBar(menu: true),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Menu', style: Helper.getTheme(context).headlineLarge),
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
    );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final filtered = docs.where((d) {
          final data = d.data()! as Map<String, dynamic>;
          final name = (data['name'] as String).toLowerCase();
          return _searchTerm.isEmpty || name.contains(_searchTerm);
        }).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('No categories found'));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final cat = doc.data()! as Map<String, dynamic>;
            return _buildCategoryCard(doc.id, cat['name'] as String, cat['imageUrl'] as String?);
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(String id, String name, String? imageUrl) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where(
            'categoryRef',
            isEqualTo: FirebaseFirestore.instance.doc(
              "/categories/$id",
            ),
          )
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: CupertinoActivityIndicator(
                color: AppColors.orangeColor,
              ),
            ),
          );
        }
        final count = snap.data!.docs.length;
        return MenuCard(
          name: name,
          count: "$count",
          imageUrl: imageUrl,
          onTap: () {
            Get.toNamed(
              DessertScreen.routeName,
              arguments: {
                'categoryId': id,
                'categoryName': name,
              },
            );
          },
        );
      },
    );
  }
}

class MenuCard extends StatelessWidget {
  final String name;
  final String count;
  final String? imageUrl;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.name,
    required this.count,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.placeholder,
              offset: Offset(0, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                  : Container(
                      width: 60, height: 60, color: const Color.fromARGB(255, 180, 190, 190)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Helper.getTheme(context).headlineMedium),
                  const SizedBox(height: 5),
                  Text('$count items'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
