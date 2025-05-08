import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/models/user_model.dart';
import 'package:shop_now_mobile/utils/constant.dart';
import 'package:shop_now_mobile/utils/dialogs.dart';

class LoginScreenController extends GetxController {
  final formKey = GlobalKey<FormState>();

  //text editing controllers
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  late UserCredential userCredential;

  /// Toggle value of hide password
  RxBool toggleHidePassword = true.obs;

  void onPasswordHideButtonTap() {
    toggleHidePassword.value = !toggleHidePassword.value;
    update();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = GetStorage();

  // Fetch user data from Firestore
  Future<UserModel?> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        log(" =========> USER EXIST");
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      } else {
        log(' =========> User document does not exist in Firestore');
        return null;
      }
    } catch (e) {
      log('Error fetching user data: $e');
      return null;
    }
  }

  void _saveUserToLocalStorage(UserModel user) {
    _storage.write(PrefKey.userId.name, user.id);
    _storage.write(PrefKey.userLastName.name, user.lastName);
    _storage.write(PrefKey.userFirstsname.name, user.firstName);
    _storage.write(PrefKey.userEmail.name, user.email);
    _storage.write(PrefKey.userPhone.name, user.phone);
    _storage.write(PrefKey.userAddress.name, user.address?.line1);
    _storage.write(PrefKey.userType.name, user.role);
    log('User data saved to local storage');
  }

  // Redirect user based on account type
  void _redirectUser(String accountType) {
    switch (accountType) {
      case 'admin':
        Get.offAllNamed(AppPageNames.adminDashboardScreen);
        break;
      case 'seller':
        Get.offAllNamed(AppPageNames.shopManagementScreen);
        break;
      case 'shopper':
        Get.offAllNamed(AppPageNames.shopperDashboardScreen);
        break;
      case 'buyer':
      default:
        Get.offAllNamed(AppPageNames.homeScreen);
    }
    log('User redirected to $accountType dashboard');
  }

  Future<void> _handleSuccessfulAuth(User user) async {
    // Fetch user data from Firestore
    UserModel? userData = await _fetchUserData(user.uid);

    if (userData != null) {
      // User exists in database, save info and redirect
      _saveUserToLocalStorage(userData);
      _redirectUser(userData.role ?? 'buyer');
    } else {
      // Create basic user profile with default customer role
      UserModel newUser = UserModel(
          id: user.uid,
          lastName: user.displayName ?? '',
          firstName: user.displayName ?? "",
          email: user.email ?? '',
          phone: '',
          address: null,
          role: 'buyer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now());

      // Store in Firestore
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // Save locally and redirect
      _saveUserToLocalStorage(newUser);
      _redirectUser('buyer');
    }
  }

  //sign in the user function
  void login() async {
    if (formKey.currentState?.validate() == false) {
      return;
    }

    AppDialogs.showProcessingDialog(message: 'Loading please wait');

    //try to sign in
    try {
      userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      Get.back(); // Close loading dialog

      // Handle authentication and redirection
      await _handleSuccessfulAuth(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      //pop the circle and show the error message
      Get.back();
      log('Firebase catch error: ${e.code}');

      AppDialogs.showErrorDialog(messageText: e.code);
    } catch (e) {
      Get.back();
      log('Error during login: $e');
      AppDialogs.showErrorDialog(messageText: 'Failed to create account. Please try again.');
    } finally {
      update();
    }
  }

  void googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential`
      userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Handle authentication and redirection
      await _handleSuccessfulAuth(userCredential.user!);
    } catch (e) {
      log(e.toString());
      if (e is PlatformException) {
        AppDialogs.showErrorDialog(messageText: e.code);
      } else {
        AppDialogs.showErrorDialog(messageText: e.toString());
      }
      return null;
    } finally {
      update();
    }
  }
}
