// lib/screens/seed_data_screen.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/address.dart';
import '../models/shopper_profile.dart';
import '../models/shop_model.dart';
import '../utils/dialogs.dart';

class SeedDataScreen extends StatelessWidget {
  static const routeName = '/seedDataScreen';
  final SeedDataController controller = Get.put(SeedDataController());

  SeedDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Firestore Data')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => controller.processing(),
          child: const Text('Denormalize products names'),
        ),
      ),
    );
  }
}

class SeedDataController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Predefined brand & category IDs
  final List<String> brandIds = [
    "09C9S00NmmQ68fsCEeJM",
    "4hD2q9Eq8TkMuvkmYTp1",
    "d82SYMm0i7lJDwE7KQRp",
  ];
  final List<String> categoryIds = [
    "LcgQyFJqDjwa3avcWCSE",
    "f2QJutGMJUAJ9NskJfde",
    "x1ZGYIhcPH7KB2oi3dVx",
  ];

  // Will hold created UIDs and product entries
  final List<String> buyerUids = [];
  final List<String> shopperUids = [];
  final List<String> verifiedShopperUids = [];
  final List<String> sellerUids = [];
  final List<Map<String, String>> productEntries = [];

  Future<void> processing() async {
    AppDialogs.showProcessingDialog(message: 'Seeding database...');
    try {
      // await _seedBuyers();
      // await _seedShoppers();
      // await _seedSellers();
      // await _seedProducts();
      // await _seedOrders();

      await _denormalizeNames();
      Get.back();
      AppDialogs.showSuccessDialog(messageText: 'All data seeded successfully.');
    } catch (e) {
      Get.back();
      AppDialogs.showErrorDialog(messageText: 'Error seeding: $e');
    }
  }

  Future<void> _seedBuyers() async {
    final now = DateTime.now();
    final users = [
      {'email': 'alice@shopnow.com', 'first': 'Alice', 'last': 'Smith'},
      {'email': 'bob@shopnow.com', 'first': 'Bob', 'last': 'Johnson'},
      {'email': 'carol@shopnow.com', 'first': 'Carol', 'last': 'Williams'},
      {'email': 'dave@shopnow.com', 'first': 'Dave', 'last': 'Brown'},
      {'email': 'eve@shopnow.com', 'first': 'Eve', 'last': 'Davis'},
    ];
    for (var u in users) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
            email: u['email']!, password: 'Password123!');
        final uid = cred.user!.uid;
        buyerUids.add(uid);
        await _auth.signOut();
        final user = UserModel(
          id: uid,
          role: 'buyer',
          email: u['email']!,
          phone: '+447700900100',
          firstName: u['first']!,
          lastName: u['last']!,
          address: Address(
            line1: '1 Cardiff Road',
            city: 'Cardiff',
            country: 'UK',
            location: const GeoPoint(51.4816, -3.1791),
          ),
          createdAt: now,
          updatedAt: now,
        );
        await _firestore.collection('users').doc(uid).set(user.toMap());
      } catch (_) {
        log(" ======> Users seeding error");
      }
    }
  }

  Future<void> _seedShoppers() async {
    final now = DateTime.now();
    final shoppers = [
      {'email': 'sam@shopnow.com', 'first': 'Sam', 'last': 'Taylor', 'verified': true},
      {'email': 'tina@shopnow.com', 'first': 'Tina', 'last': 'Anderson', 'verified': true},
      {'email': 'uma@shopnow.com', 'first': 'Uma', 'last': 'Thomas', 'verified': true},
      {'email': 'victor@shopnow.com', 'first': 'Victor', 'last': 'Hughes', 'verified': false},
      {'email': 'winona@shopnow.com', 'first': 'Winona', 'last': 'Clark', 'verified': false},
    ];
    for (var s in shoppers) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
            email: s['email'] as String, password: 'Password123!');
        final uid = cred.user!.uid;
        shopperUids.add(uid);
        if (s['verified'] == true) verifiedShopperUids.add(uid);
        await _auth.signOut();
        final user = UserModel(
          id: uid,
          role: 'shopper',
          email: s['email']! as String,
          phone: '+447700900101',
          firstName: s['first']! as String,
          lastName: s['last']! as String,
          address: Address(
            line1: '2 Cardiff Road',
            city: 'Cardiff',
            country: 'UK',
            location: const GeoPoint(51.4820, -3.1800),
          ),
          createdAt: now,
          updatedAt: now,
        );

        await _firestore.collection('users').doc(uid).set(user.toMap());
        final shopperProfileDoc =
            _firestore.collection('users').doc(uid).collection('shopperProfile').doc();
        final prof = ShopperProfile(
          id: shopperProfileDoc.id,
          verificationStatus: s['verified'] as bool ? 'approved' : 'pending',
          availability: s['verified'] as bool,
          currentLocation: null,
          geohash: null,
          createdAt: now,
          updatedAt: now,
        );
        await shopperProfileDoc.set(prof.toMap());
      } catch (_) {
        log(" ======> Shoppers seeding error");
      }
    }
  }

  Future<void> _seedSellers() async {
    final now = DateTime.now();
    final sellers = [
      {'email': 'tim@shopnow.com', 'first': 'Tim', 'last': 'Lee', 'shop': 'Tim\'s Tools'},
      {'email': 'nina@shopnow.com', 'first': 'Nina', 'last': 'Scott', 'shop': 'Nina\'s Nook'},
      {'email': 'oscar@shopnow.com', 'first': 'Oscar', 'last': 'Reed', 'shop': 'Oscar\'s Outlet'},
      {'email': 'paula@shopnow.com', 'first': 'Paula', 'last': 'Green', 'shop': 'Paula\'s Place'},
      {
        'email': 'quinn@shopnow.com',
        'first': 'Quinn',
        'last': 'Adams',
        'shop': 'Quinn\'s Quickmart'
      },
    ];
    for (var s in sellers) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
            email: s['email']!, password: 'Password123!');
        final uid = cred.user!.uid;
        sellerUids.add(uid);
        await _auth.signOut();
        final user = UserModel(
          id: uid,
          role: 'seller',
          email: s['email']!,
          phone: '+447700900102',
          firstName: s['first']!,
          lastName: s['last']!,
          address: Address(
            line1: '3 Cardiff Road',
            city: 'Cardiff',
            country: 'UK',
            location: const GeoPoint(51.4825, -3.1785),
          ),
          createdAt: now,
          updatedAt: now,
        );
        await _firestore.collection('users').doc(uid).set(user.toMap());
        final shop = Shop(
          id: uid,
          userRef: _firestore.doc('users/$uid'),
          name: s['shop']!,
          address: Address(
            line1: '${s['shop']!} Address',
            city: 'Cardiff',
            country: 'UK',
            location: const GeoPoint(51.4830, -3.1770),
          ),
          createdAt: now,
          updatedAt: now,
        );
        final shopDoc = _firestore.collection('shops').doc();
        await shopDoc.set(shop.toMap());
      } catch (_) {
        log(" ======> Sellers seeding error");
      }
    }
  }

  Future<void> _seedProducts() async {
    try {
      final now = DateTime.now();
      for (var i = 0; i < sellerUids.length; i++) {
        final sellerUid = sellerUids[i];
        for (var j = 0; j < 5; j++) {
          final pid = 'prod_${i}_$j';
          final bid = brandIds[j % brandIds.length];
          final cid = categoryIds[j % categoryIds.length];
          final productDoc = _firestore.collection('products').doc();
          await productDoc.set({
            'id': productDoc.id,
            'name': 'Product $pid',
            'description': 'Desc for $pid',
            'brandRef': _firestore.doc('brands/$bid'),
            'brandName': null,
            'categoryRef': _firestore.doc('categories/$cid'),
            'categoryName': null,
            'price': (10 + j * 5).toDouble(),
            'originalPrice': (10 + j * 5).toDouble(),
            'unit': 'each',
            'stock': 20 + j,
            'featured': false,
            'imageUrl': '',
            'sellerRef': _firestore.doc('shops/$sellerUid'),
            'createdAt': now,
            'updatedAt': now,
          });
          productEntries.add({'id': pid, 'sellerUid': sellerUid});
        }
      }
      // Denormalize names ...
      for (var bid in brandIds) {
        final bdoc = await _firestore.collection("brands").doc(bid).get();
        final bn = bdoc['name'];
        log(" =======> Brand name: $bn");
        final qs = await _firestore
            .collection('products')
            .where('brandRef', isEqualTo: _firestore.doc('brands/$bid'))
            .get();
        log(" ==========> Brand products number: ${qs.docs.length}");
        for (var d in qs.docs) {
          d.reference.update({'brandName': bn});
        }
      }
      for (var cid in categoryIds) {
        final cdoc = await _firestore.collection("categories").doc(cid).get();
        final cn = cdoc['name'];
        log(" ===========> Category name: $cn");
        final qs = await _firestore
            .collection('products')
            .where('categoryRef', isEqualTo: _firestore.doc('categories/$cid'))
            .get();
        log(" ==========> Category products number: ${qs.docs.length}");

        for (var d in qs.docs) {
          d.reference.update({'categoryName': cn});
        }
      }
    } catch (e) {
      log(" ======> Products seeding error");
      log("======= Error: $e");
    }
  }

  Future<void> _denormalizeNames() async {
    try {
      final brandsSnapshot = await _firestore.collection("brands").get();
      if (brandsSnapshot.docs.isNotEmpty) {
        final firstBrandId = brandsSnapshot.docs.first.id;
        log(" =========> First brand Id: $firstBrandId");
      } else {
        log(" =========> No brands found in the collection.");
      }

      // Denormalize brand names
      for (var bid in brandIds) {
        log(" =========> Processing Brand ID: $bid");
        final bdoc = await _firestore.collection("brands").doc(bid).get();

        if (bdoc.exists && bdoc.data() != null) {
          log(" =========> Brand doc exists: ${bdoc.data().toString()}");
          final bn = bdoc.data()!['name']; // Use null safety here
          log(" =======> Brand name: $bn");
          final qs = await _firestore
              .collection('products')
              .where('brandRef', isEqualTo: _firestore.doc('brands/$bid'))
              .get();
          log(" ==========> Brand products number for $bid: ${qs.docs.length}");
          for (var d in qs.docs) {
            await d.reference.update({'brandName': bn}); // Use await for updates
          }
        } else {
          log(" =========> Brand document with ID '$bid' does not exist!");
        }
      }

      // Denormalize category names
      for (var cid in categoryIds) {
        log(" ===========> Processing Category ID: $cid");
        final cdoc = await _firestore.collection("categories").doc(cid).get();

        if (cdoc.exists && cdoc.data() != null) {
          final cn = cdoc.data()!['name']; // Use null safety here
          log(" ===========> Category name: $cn");
          final qs = await _firestore
              .collection('products')
              .where('categoryRef', isEqualTo: _firestore.doc('categories/$cid'))
              .get();
          log(" ==========> Category products number for $cid: ${qs.docs.length}");

          for (var d in qs.docs) {
            await d.reference.update({'categoryName': cn}); // Use await for updates
          }
        } else {
          log(" ===========> Category document with ID '$cid' does not exist!");
        }
      }
    } catch (e) {
      log(" ==========> Denormalizing error: $e");
    }
  }

  Future<void> _seedOrders() async {
    try {
      final now = DateTime.now();
      if (buyerUids.isEmpty || verifiedShopperUids.isEmpty || sellerUids.isEmpty) return;
      for (var i = 0; i < buyerUids.length; i++) {
        final buyUid = buyerUids[i];
        final entry = productEntries[i % productEntries.length];
        final shopUid = sellerUids.firstWhere((s) => s == entry['sellerUid']);
        final shoprUid = verifiedShopperUids[i % verifiedShopperUids.length];
        final oid = 'order_${i + 1}';
        await _firestore.collection('orders').doc(oid).set({
          'id': oid,
          'buyerRef': _firestore.doc('users/$buyUid'),
          'shopperRef': _firestore.doc('users/$shoprUid'),
          'shopRef': _firestore.doc('shops/$shopUid'),
          'items': [
            {
              'productRef': _firestore.doc('products/${entry['id']}'),
              'name': entry['id'],
              'quantity': 1,
              'unit': 'each',
              'price': 10.0
            }
          ],
          'total': 10.0,
          'status': 'active',
          'requestedAt': now,
          'acceptedAt': now,
          'pickedUpAt': now,
          'deliveredAt': null,
          'storeLocation': const GeoPoint(51.4821, -3.1811),
          'deliveryLocation': const GeoPoint(51.4619, -3.1644),
          'geohashStore': null,
          'geohashDelivery': null,
          'distanceText': null,
          'timeText': null,
          'createdAt': now,
          'updatedAt': now,
        });
      }
    } catch (e) {
      log(" ======> Orders seeding error");
    }
  }
}
