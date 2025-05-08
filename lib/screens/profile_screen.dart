import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_gaps.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/models/user_model.dart';
import 'package:shop_now_mobile/utils/constant.dart';
import 'package:shop_now_mobile/utils/dialogs.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:shop_now_mobile/widgets/custom_nav_bar.dart';

class ProfileScreenController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _getStorage = GetStorage();
  final ImagePicker _imagePicker = ImagePicker();

  // User data
  late User user;
  UserModel? userProfile;

  // Form controllers
  final lastNameController = TextEditingController();
  final firstnameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String lastname = "", firstname = "";

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Editing state
  RxBool isEditing = false.obs;
  RxBool isLoading = false.obs;
  RxBool isChangingPassword = false.obs;
  RxString profileImageUrl = ''.obs;
  Rx<File?> selectedImage = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    user = _auth.currentUser!;
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    isLoading.value = true;
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Set initial values for controllers
        lastNameController.text = userData['name']?['last'] ?? user.displayName ?? '';
        lastname = userData['name']?['last'] ?? "";
        firstnameController.text = userData['name']?['first'] ?? user.displayName ?? "";
        firstname = userData['name']?['first'] ?? "";
        emailController.text = userData['email'] ?? user.email ?? '';
        phoneController.text = userData['phone'] ?? user.phoneNumber ?? '';
        addressController.text = userData['address']?['line1'] ?? '';
        profileImageUrl.value = userData['profileImage'] ?? '';

        update();
      }
    } catch (e) {
      log('Error fetching user profile: $e');
      AppDialogs.showErrorDialog(messageText: 'Failed to load profile data');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleEditMode() {
    isEditing.value = !isEditing.value;
    update();
  }

  void togglePasswordChange() {
    isChangingPassword.value = !isChangingPassword.value;
    // Clear password fields when toggling
    passwordController.clear();
    confirmPasswordController.clear();
    update();
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        update();
      }
    } catch (e) {
      log('Error picking image: $e');
      AppDialogs.showErrorDialog(messageText: 'Failed to select image');
    }
  }

  Future<String?> uploadProfileImage() async {
    if (selectedImage.value == null) return profileImageUrl.value;

    try {
      String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      Reference storageRef = _storage.ref().child('profile_images/$fileName');

      await storageRef.putFile(selectedImage.value!);
      String downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      log('Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> updateUserProfile() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    isLoading.value = true;
    AppDialogs.showProcessingDialog(message: 'Updating profile...');

    try {
      // Upload image if selected
      String? imageUrl;
      /*   if (selectedImage.value != null) {
        imageUrl = await uploadProfileImage();
        if (imageUrl == null) {
          Get.back();
          AppDialogs.showErrorDialog(messageText: 'Failed to upload profile image');
          isLoading.value = false;
          return;
        }
      }
      */

      // Update user profile in Firestore
      Map<String, dynamic> updateData = {
        'name': {
          'last': lastNameController.text,
          'first': firstnameController.text,
        },
        // 'firstName': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'address': {
          "line1": addressController.text,
        },
        'updatedAt': DateTime.now(),
      };
      /* 
      if (imageUrl != null) {
        updateData['profileImage'] = imageUrl;
        profileImageUrl.value = imageUrl;
      }
      */

      await _firestore.collection('users').doc(user.uid).update(updateData);

      // Update Auth profile
      await user.updateDisplayName(firstnameController.text);

      // Update local storage
      _getStorage.write(PrefKey.userLastName.name, lastNameController.text);
      _getStorage.write(PrefKey.userFirstsname.name, firstnameController.text);
      _getStorage.write(PrefKey.userEmail.name, emailController.text);
      _getStorage.write(PrefKey.userPhone.name, phoneController.text);
      _getStorage.write(PrefKey.userAddress.name, addressController.text);

      Get.back(); // Close loading dialog
      AppDialogs.showSuccessDialog(messageText: 'Profile updated successfully');

      // Refresh profile data
      fetchUserProfile();

      // Exit edit mode
      isEditing.value = false;
    } catch (e) {
      Get.back();
      log('Error updating profile: $e');
      AppDialogs.showErrorDialog(messageText: 'Failed to update profile: ${e.toString()}');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> updatePassword() async {
    if (passwordController.text != confirmPasswordController.text) {
      AppDialogs.showErrorDialog(messageText: 'Passwords do not match');
      return;
    }

    if (passwordController.text.length < 6) {
      AppDialogs.showErrorDialog(messageText: 'Password must be at least 6 characters');
      return;
    }

    isLoading.value = true;
    AppDialogs.showProcessingDialog(message: 'Updating password...');

    try {
      await user.updatePassword(passwordController.text);

      Get.back(); // Close loading dialog
      AppDialogs.showSuccessDialog(messageText: 'Password updated successfully');

      // Clear password fields and exit password change mode
      passwordController.clear();
      confirmPasswordController.clear();
      isChangingPassword.value = false;
    } catch (e) {
      Get.back();
      log('Error updating password: $e');

      // Handle specific auth errors
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          AppDialogs.showErrorDialog(
            messageText: 'Please sign in again before changing your password',
          );
        } else {
          AppDialogs.showErrorDialog(messageText: e.message ?? 'Failed to update password');
        }
      } else {
        AppDialogs.showErrorDialog(messageText: 'Failed to update password');
      }
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _getStorage.erase(); // Clear all stored data
      Get.offAllNamed(AppPageNames.loginScreen);
    } catch (e) {
      log('Error signing out: $e');
      AppDialogs.showErrorDialog(messageText: 'Failed to sign out');
    }
  }
}

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profileScreen';
  final ProfileScreenController controller = Get.put(ProfileScreenController());

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return SingleChildScrollView(
                child: SizedBox(
                  height: Helper.getScreenHeight(context),
                  width: Helper.getScreenWidth(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile',
                                style: Helper.getTheme(context).headlineLarge,
                              ),
                              IconButton(
                                onPressed: controller.signOut,
                                icon: Icon(
                                  Icons.logout_outlined,
                                  color: AppColors.primaryMaterialColor,
                                ),
                              ),
                            ],
                          ),
                          // Content
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  AppGaps.hGap20,

                                  // Avatar & Edit Icon
                                  Obx(() {
                                    final img = controller.selectedImage.value;
                                    final url = controller.profileImageUrl.value;
                                    return GestureDetector(
                                      onTap:
                                          controller.isEditing.value ? controller.pickImage : null,
                                      child: Stack(
                                        children: [
                                          ClipOval(
                                            child: Container(
                                              height: 100,
                                              width: 100,
                                              decoration: const BoxDecoration(
                                                color: AppColors.placeholderBg,
                                                shape: BoxShape.circle,
                                              ),
                                              child: img != null
                                                  ? Image.file(
                                                      img,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : url.isNotEmpty
                                                      ? Image.network(url,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stack) =>
                                                              Container(
                                                                decoration: const BoxDecoration(
                                                                  color: AppColors.placeholderBg,
                                                                ),
                                                                child: Icon(
                                                                  Icons.person_rounded,
                                                                  color: AppColors
                                                                      .primaryMaterialColor,
                                                                  size: 50.0,
                                                                ),
                                                              ))
                                                      : Container(
                                                          decoration: const BoxDecoration(
                                                            color: AppColors.placeholderBg,
                                                          ),
                                                          child: Icon(
                                                            Icons.person_rounded,
                                                            color: AppColors.primaryMaterialColor,
                                                            size: 50.0,
                                                          ),
                                                        ),
                                            ),
                                          ),
                                          if (controller.isEditing.value)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: CircleAvatar(
                                                radius: 12,
                                                backgroundColor: AppColors.primaryMaterialColor,
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  size: 16,
                                                  color: AppColors.whiteColor,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                  AppGaps.hGap10,

                                  // Edit Toggle
                                  GestureDetector(
                                    onTap: controller.toggleEditMode,
                                    child: Obx(() => Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              Helper.getAssetName(
                                                'edit_filled.png',
                                                'virtual',
                                              ),
                                            ),
                                            AppGaps.wGap5,
                                            Text(
                                              controller.isEditing.value
                                                  ? 'Cancel Editing'
                                                  : 'Edit Profile',
                                              style: const TextStyle(
                                                color: AppColors.orangeColor,
                                              ),
                                            ),
                                          ],
                                        )),
                                  ),
                                  AppGaps.hGap10,

                                  // Greeting
                                  // Obx(() =>
                                  Text(
                                    "Hi there ${controller.firstname} ${controller.lastname}!",
                                    style: Helper.getTheme(context).headlineMedium?.copyWith(
                                          color: AppColors.greyDark,
                                        ),
                                  )

                                  //)
                                  ,
                                  AppGaps.hGap40,

                                  // Lastname
                                  Obx(() => CustomFormInput(
                                        label: 'Lastname',
                                        controller: controller.lastNameController,
                                        enabled: controller.isEditing.value,
                                        validator: (val) {
                                          if (controller.isEditing.value &&
                                              (val == null || val.isEmpty)) {
                                            return 'Please enter your lastname';
                                          }
                                          return null;
                                        },
                                      )),
                                  AppGaps.hGap20,

                                  // Firstname
                                  Obx(() => CustomFormInput(
                                        label: 'Firstname',
                                        controller: controller.firstnameController,
                                        enabled: controller.isEditing.value,
                                        validator: (val) {
                                          if (controller.isEditing.value &&
                                              (val == null || val.isEmpty)) {
                                            return 'Please enter your firstname';
                                          }
                                          return null;
                                        },
                                      )),
                                  AppGaps.hGap20,

                                  // Email (read-only)
                                  CustomFormInput(
                                    label: 'Email',
                                    controller: controller.emailController,
                                    enabled: false,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  AppGaps.hGap20,

                                  // Phone
                                  Obx(() => CustomFormInput(
                                        label: 'Mobile No',
                                        controller: controller.phoneController,
                                        enabled: controller.isEditing.value,
                                        keyboardType: TextInputType.phone,
                                        validator: (val) {
                                          if (controller.isEditing.value &&
                                              val != null &&
                                              val.isNotEmpty &&
                                              !val.isPhoneNumber) {
                                            return 'Please enter a valid phone number';
                                          }
                                          return null;
                                        },
                                      )),
                                  AppGaps.hGap20,

                                  // Address
                                  Obx(() => CustomFormInput(
                                        label: 'Address',
                                        controller: controller.addressController,
                                        enabled: controller.isEditing.value,
                                        maxLines: 2,
                                      )),
                                  AppGaps.hGap20,

                                  // Change Password Section
                                  Obx(() {
                                    if (!controller.isEditing.value) {
                                      return const SizedBox.shrink();
                                    }
                                    if (controller.isChangingPassword.value) {
                                      return Column(
                                        children: [
                                          CustomFormInput(
                                            label: 'New Password',
                                            controller: controller.passwordController,
                                            enabled: true,
                                            isPassword: true,
                                            validator: (val) {
                                              if (val == null || val.isEmpty) {
                                                return 'Password cannot be empty';
                                              }
                                              if (val.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                          AppGaps.hGap20,
                                          CustomFormInput(
                                            label: 'Confirm Password',
                                            controller: controller.confirmPasswordController,
                                            enabled: true,
                                            isPassword: true,
                                            validator: (val) {
                                              if (val != controller.passwordController.text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                          ),
                                          AppGaps.hGap10,
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              TextButton(
                                                onPressed: controller.togglePasswordChange,
                                                child: const Text('Cancel'),
                                              ),
                                              AppGaps.wGap20,
                                              ElevatedButton(
                                                onPressed: controller.updatePassword,
                                                child: const Text('Update Password'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }
                                    return OutlinedButton.icon(
                                      onPressed: controller.togglePasswordChange,
                                      icon: const Icon(Icons.lock_outline),
                                      label: const Text('Change Password'),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: Size(
                                          Helper.getScreenWidth(context) * 0.8,
                                          45,
                                        ),
                                      ),
                                    );
                                  }),
                                  AppGaps.hGap30,

                                  // Save Button
                                  Obx(() {
                                    if (controller.isEditing.value &&
                                        !controller.isChangingPassword.value) {
                                      return SizedBox(
                                        height: 50,
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: controller.updateUserProfile,
                                          child: const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: AppColors.whiteColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                  AppGaps.hGap120,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            child: CustomNavBar(
              profile: true,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomFormInput extends StatelessWidget {
  const CustomFormInput({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final bool enabled;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: enabled ? AppColors.placeholderBg : AppColors.placeholderBg.withOpacity(0.7),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
        ),
        obscureText: isPassword,
        enabled: enabled,
        maxLines: isPassword ? 1 : maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 14,
          color: enabled ? Colors.black : Colors.black54,
        ),
      ),
    );
  }
}
