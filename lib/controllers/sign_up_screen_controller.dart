import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/models/address.dart';
import 'package:shop_now_mobile/models/shop_model.dart';
import 'package:shop_now_mobile/models/shopper_profile.dart';
import 'package:shop_now_mobile/widgets/location_picker_form_field.dart';
import '../models/user_model.dart';
import '../utils/dialogs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class SignUpScreenController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final selectedAccountType = 'buyer'.obs;

  // Name
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  // Common
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Seller
  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final storeLocation = Rx<LocationResult?>(null);

  // Government ID document for shoppers
  final governmentIdFile = Rx<PlatformFile?>(null);
  final governmentIdError = ''.obs;

  // Toggles
  final toggleHidePassword = true.obs;
  final confirmToggleHidePassword = true.obs;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String? nameValidator(String? v) =>
      (v == null || v.isEmpty || v.length < 2) ? 'Min 2 chars' : null;
  String? emailValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    //  final rx = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$');
    return GetUtils.isEmail(v) ? null : 'Invalid';
  }

  String? phoneValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final cleaned = v.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.startsWith('+44') ? null : 'Must start +44';
  }

  String? passwordValidator(String? v) => (v == null || v.length < 7) ? 'Min 7 chars' : null;
  String? confirmPasswordValidator(String? v) =>
      (v != passwordController.text) ? 'Not match' : null;

  void onPasswordHideButtonTap() => toggleHidePassword.value = !toggleHidePassword.value;
  void onConfirmPasswordHideButtonTap() =>
      confirmToggleHidePassword.value = !confirmToggleHidePassword.value;

  Future<void> pickGovernmentIdFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        governmentIdFile.value = result.files.first;
        governmentIdError.value = '';
      }
    } catch (e) {
      log('Error picking file: $e');
      governmentIdError.value = 'Failed to select file. Please try again.';
    }
  }

  void clearGovernmentIdFile() {
    governmentIdFile.value = null;
  }

  bool _validateShopperGovernmentId() {
    if (selectedAccountType.value == 'shopper' && governmentIdFile.value == null) {
      governmentIdError.value = 'Government ID document is required';
      return false;
    }
    return true;
  }

  Future<String?> _uploadGovernmentId(String uid) async {
    if (governmentIdFile.value == null) return null;

    try {
      final file = File(governmentIdFile.value!.path!);
      final ext = path.extension(governmentIdFile.value!.name);
      final fileName = 'government_ids/$uid/id_document$ext';

      final storageRef = _storage.ref().child(fileName);
      final uploadTask = storageRef.putFile(file);

      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      log('Error uploading government ID: $e');
      throw Exception('Failed to upload government ID document');
    }
  }

  Future<void> signUp() async {
    if (formKey.currentState?.validate() != true) return;

    // Validate government ID for shoppers
    if (!_validateShopperGovernmentId()) return;

    AppDialogs.showProcessingDialog(message: 'Please wait...');
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      final uid = cred.user!.uid;
      final now = DateTime.now();

      final user = UserModel(
        id: uid,
        role: selectedAccountType.value,
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        address: Address(line1: addressController.text.trim()),
        createdAt: now,
        updatedAt: now,
      );
      await _firestore.collection('users').doc(uid).set(user.toMap());

      if (selectedAccountType.value == 'shopper') {
        // Upload government ID document
        //  final governmentIdUrl = await _uploadGovernmentId(uid);

        final shopperProfileDoc =
            _firestore.collection('users').doc(uid).collection('shopperProfile').doc();

        await shopperProfileDoc.set(
          ShopperProfile(
            id: shopperProfileDoc.id,
            verificationStatus: 'pending',
            availability: false,
            currentLocation: null,
            geohash: null,
            //    governmentIdUrl: governmentIdUrl,
            governmentIdUrl: '',
            createdAt: now,
            updatedAt: now,
          ).toMap(),
        );
      }

      if (selectedAccountType.value == 'seller') {
        final userShop = _firestore.collection('shops').doc();
        userShop.set(
          Shop(
            id: userShop.id,
            userRef: _firestore.doc('users/$uid'),
            name: storeNameController.text.trim(),
            address: Address(
                line1: storeAddressController.text.trim(),
                location: storeLocation.value != null
                    ? GeoPoint(
                        storeLocation.value!.lat,
                        storeLocation.value!.lng,
                      )
                    : null),
            createdAt: now,
            updatedAt: now,
          ).toMap(),
        );
      }

      AppDialogs.showSuccessDialog(messageText: 'Account created!');
    } on FirebaseAuthException catch (e) {
      Get.back();
      AppDialogs.showErrorDialog(messageText: e.message ?? 'Auth error');
    } catch (e) {
      Get.back();
      log('Error: $e');
      AppDialogs.showErrorDialog(messageText: 'Signup failed');
    }
  }
}
