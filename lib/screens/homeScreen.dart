// lib/screens/home_screen.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:shop_now_mobile/const/app_gaps.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/controllers/main_cart_controller.dart';
import 'package:shop_now_mobile/screens/individualItem.dart';
import 'package:shop_now_mobile/screens/shopProductsScreen.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:shop_now_mobile/widgets/custom_nav_bar.dart';
import 'package:shop_now_mobile/widgets/home_widget.dart';
import 'package:shop_now_mobile/widgets/location_picker_form_field.dart';
import 'package:shop_now_mobile/widgets/searchBar.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = "/homeScreen";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedLocation = 'Current Location';
  final MainCartController cartController = Get.find<MainCartController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppGaps.hGap20,
              _buildHeader(context),
              AppGaps.hGap20,
              _buildLocationPicker(context),
              AppGaps.hGap20,

              AppGaps.hGap20,
              _buildSectionTitle('Categories'),
              AppGaps.hGap20,
              _buildCategoriesCarousel(),
              AppGaps.hGap20,
              _buildSectionTitle('Popular Brands'),
              AppGaps.hGap20,
              _buildBrandsCarousel(),
              AppGaps.hGap50,
              _buildSectionTitleRow('Popular Shops', 'View all', AppPageNames.shopsListScreen),
              AppGaps.hGap20,
              _buildShopsList(),
              // *  AppGaps.hGap50,
              /*  _buildSectionTitleRow('Popular Shoes', 'View all', AppPageNames.myOrderScreen), 
              AppGaps.hGap20,
              _buildPopularShoes(), 
              AppGaps.hGap50,*/
              /*  _buildSectionTitleRow('Most Popular', 'View all', AppPageNames.myOrderScreen),
              AppGaps.hGap20,
              _buildMostPopular(),
              AppGaps.hGap50, */
              _buildSectionTitleRow('Recent Items', 'View all', AppPageNames.myOrderScreen),
              AppGaps.hGap20,
              _buildRecentItems(),
              AppGaps.hGap100,
            ],
          ),
        ),
      ),
      bottomSheet: const IntrinsicHeight(
        child: CustomNavBar(home: true),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Good morning ${Helper.getUserName()}!',
              overflow: TextOverflow.ellipsis,
              style: Helper.getTheme(context).headlineLarge,
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

  Widget _buildLocationPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivering to', style: Helper.getTheme(context).bodyLarge),
          const SizedBox(height: 8),
          LocationPickerInput(onLocationSelected: (loc) {
            setState(() {
              _selectedLocation = loc.address;
            });
          })
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: Helper.getTheme(context).headlineLarge),
    );
  }

  Widget _buildSectionTitleRow(String title, String action, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Helper.getTheme(context).headlineLarge),
          TextButton(onPressed: () => Get.toNamed(route), child: Text(action)),
        ],
      ),
    );
  }

  Widget _buildCategoriesCarousel() {
    return SizedBox(
      height: 140,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('categories').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = docs[i];
              return InkWell(
                onTap: () => Get.toNamed(
                  AppPageNames.dessertScreen,
                  arguments: {
                    'categoryId': snap.data!.docs[i].id,
                    'categoryName': c['name'],
                  },
                ),
                child: CategoryCard(
                  name: c['name'],
                  image: c['imageUrl'].isEmpty
                      ? null
                      : Image.network(c['imageUrl'] ?? '', fit: BoxFit.cover),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBrandsCarousel() {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('brands').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 25),
            itemBuilder: (context, i) {
              final b = docs[i];
              return InkWell(
                onTap: () => Get.toNamed(
                  AppPageNames.dessertScreen,
                  arguments: {
                    'brandId': snap.data!.docs[i].id,
                    'brandName': b['name'],
                  },
                ),
                child: BrandCard(
                  name: b['name'],
                  image: b['logoUrl'].isEmpty ? null : SvgPicture.network(b['logoUrl'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShopsList() {
    return SizedBox(
      height: 250,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('shops').limit(5).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            //  padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final s = docs[i];
              return InkWell(
                onTap: () {
                  Get.toNamed(ShopProductsScreen.routeName,
                      arguments: {'shopId': s['id'], 'shopName': s['name']});
                },
                child: RestaurantCard(
                  name: s['name'],
                  image: (s['coverImage'].runtimeType == String && s['coverImage'].isEmpty) ||
                          s['coverImage'] == null
                      ? null
                      : Image.network(s['coverImage'], fit: BoxFit.cover),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPopularShoes() {
    return SizedBox(
      height: 270,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('products')
            .where('categoryId', isEqualTo: '<shoesCategoryId>')
            .orderBy('popularity', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final p = docs[i];
              return RestaurantCard(
                name: p['name'],
                image: Image.network(p['imageUrl'] ?? '', fit: BoxFit.cover),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMostPopular() {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('products')
            .orderBy('rating', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 30),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final p = docs[i];
              return MostPopularCard(
                name: p['name'],
                image: Image.network(p['imageUrl'] ?? '', fit: BoxFit.cover),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();
        final docs = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: docs.map((r) {
              return InkWell(
                onTap: () =>
                    Get.toNamed(IndividualItem.routeName, arguments: {"productId": r['id']}),
                child: RecentItemCard(
                  name: r['name'],
                  image: r['imageUrl'].runtimeType == Null || r['imageUrl'].isEmpty
                      ? null
                      : Image.network(r['imageUrl'] ?? '', fit: BoxFit.cover),
                  shopName: "",
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
