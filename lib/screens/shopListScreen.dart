import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/models/shop_model.dart';
import 'package:shop_now_mobile/screens/shopProductsScreen.dart';

class ShopsListScreen extends StatelessWidget {
  static const routeName = '/shopsListScreen';
  const ShopsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Shops'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('shops').snapshots(),
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
            return const Center(child: Text('No shops available'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final shop = Shop.fromMap(doc.data());
              return ListTile(
                leading: Icon(Icons.store, color: AppColors.primaryMaterialColor),
                title: Text(shop.name),
                subtitle: Text(shop.address.line1),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.toNamed(ShopProductsScreen.routeName,
                      arguments: {'shopId': shop.id, 'shopName': shop.name});
                },
              );
            },
          );
        },
      ),
    );
  }
}
