// lib/screens/update_user_ids_screen.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateUserIdsScreen extends StatefulWidget {
  static const String routeName = '/updateUserIds';
  const UpdateUserIdsScreen({super.key});

  @override
  _UpdateUserIdsScreenState createState() => _UpdateUserIdsScreenState();
}

class _UpdateUserIdsScreenState extends State<UpdateUserIdsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isUpdating = false;

  Future<void> _updateIds() async {
    setState(() => _isUpdating = true);
    final batch = _firestore.batch();
    final ordersSnapshot = await _firestore.collection('products').get();
    for (final doc in ordersSnapshot.docs) {
      // Check if the 'id' field already exists and has a different value
      if (doc.data().containsKey('id') && doc.data()['id'] != doc.id) {
        batch.update(doc.reference, {'id': doc.id});
      }
      // If 'id' doesn't exist, add it
      else if (!doc.data().containsKey('id')) {
        batch.update(doc.reference, {'id': doc.id});
      }
      // If 'id' exists and has the correct value, no update is needed
    }
    try {
      await batch.commit();
      Get.snackbar('Success', 'Products IDs updated successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update IDs: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Products IDs'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _isUpdating ? null : _updateIds,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: _isUpdating
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Update Products IDs'),
        ),
      ),
    );
  }
}
