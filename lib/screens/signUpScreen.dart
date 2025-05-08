// lib/screens/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/widgets/location_picker_form_field.dart';
import '../const/app_gaps.dart';
import '../const/app_images.dart';
import '../const/app_colors.dart';
import '../widgets/customTextInput.dart';
import '../controllers/sign_up_screen_controller.dart';
import 'package:file_picker/file_picker.dart';

class SignUpScreen extends StatelessWidget {
  static const routeName = '/signUpScreen';
  final SignUpScreenController controller = Get.put(SignUpScreenController());

  SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(AppAssetImages.shopNowLogoPNG),
                const SizedBox(height: 20),
                _buildAccountTypeSelector(),
                AppGaps.hGap20,
                Column(
                  children: [
                    CustomTextInput(
                      controller: controller.firstNameController,
                      labelText: 'First Name',
                      hintText: 'John',
                      prefixIcon: SvgPicture.asset(AppAssetImages.profileSVGLogoLine),
                      validator: controller.nameValidator,
                    ),
                    const SizedBox(height: 12),
                    CustomTextInput(
                      controller: controller.lastNameController,
                      labelText: 'Last Name',
                      hintText: 'Doe',
                      prefixIcon: SvgPicture.asset(AppAssetImages.profileSVGLogoLine),
                      validator: controller.nameValidator,
                    ),
                  ],
                ),
                AppGaps.hGap20,
                CustomTextInput(
                  controller: controller.emailController,
                  labelText: 'Email',
                  hintText: 'contact@gmail.com',
                  prefixIcon: SvgPicture.asset(AppAssetImages.messageSVGLogoLine),
                  validator: controller.emailValidator,
                ),
                AppGaps.hGap20,
                CustomTextInput(
                  controller: controller.phoneController,
                  labelText: 'Phone Number',
                  hintText: '+44 1234 5678',
                  prefixIcon: SvgPicture.asset(AppAssetImages.phoneSVGLogoLine),
                  validator: controller.phoneValidator,
                ),
                AppGaps.hGap20,

                CustomTextInput(
                  controller: controller.addressController,
                  labelText: 'Address',
                  hintText: '1234 Street, City, Country',
                  prefixIcon: SvgPicture.asset(AppAssetImages.homeSVGLogoLine),
                ),
                Obx(() => controller.selectedAccountType.value == 'seller'
                    ? Column(
                        children: [
                          AppGaps.hGap20,
                          CustomTextInput(
                            controller: controller.storeNameController,
                            labelText: 'Shop Name',
                            hintText: 'My Store',
                            // prefixIcon: SvgPicture.asset(AppAssetImages.shopSVGLogoLine),
                            validator: (v) => v == null || v.isEmpty ? 'Shop name required' : null,
                          ),
                          AppGaps.hGap20,
                          LocationPickerInput(
                            controller: controller.storeAddressController,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Shop address required' : null,
                            onLocationSelected: (location) {
                              controller.storeLocation.value = location;
                            },
                          )
                        ],
                      )
                    : const SizedBox()),

                // Add government ID upload for shoppers
                Obx(() => controller.selectedAccountType.value == 'shopper'
                    ? Column(
                        children: [
                          AppGaps.hGap20,
                          _buildIdUploadSection(),
                        ],
                      )
                    : const SizedBox()),

                AppGaps.hGap20,
                CustomTextInput(
                  controller: controller.passwordController,
                  labelText: 'Password',
                  hintText: '********',
                  isPasswordTextField: controller.toggleHidePassword.value,
                  prefixIcon: SvgPicture.asset(AppAssetImages.unlockSVGLogoLine),
                  suffixIcon: IconButton(
                    onPressed: controller.onPasswordHideButtonTap,
                    icon: SvgPicture.asset(AppAssetImages.hideSVGLogoLine),
                  ),
                  validator: controller.passwordValidator,
                ),
                AppGaps.hGap20,
                CustomTextInput(
                  controller: controller.confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: '********',
                  isPasswordTextField: controller.confirmToggleHidePassword.value,
                  prefixIcon: SvgPicture.asset(AppAssetImages.unlockSVGLogoLine),
                  suffixIcon: IconButton(
                    onPressed: controller.onConfirmPasswordHideButtonTap,
                    icon: SvgPicture.asset(AppAssetImages.hideSVGLogoLine),
                  ),
                  validator: controller.confirmPasswordValidator,
                ),
                AppGaps.hGap40,
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.signUp,
                    child: const Text('Sign Up'),
                  ),
                ),
                AppGaps.hGap20,
                GestureDetector(
                  onTap: () => Get.toNamed('/loginScreen'),
                  child: const Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account?',
                        children: [
                          TextSpan(
                            text: ' Login',
                            style: TextStyle(
                              color: AppColors.orangeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeSelector() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Account Type:'),
          AppGaps.hGap10,
          Column(
            children: ['buyer', 'shopper', 'seller'].map((role) {
              return RadioListTile<String>(
                title: Text(role.capitalizeFirst!),
                value: role,
                groupValue: controller.selectedAccountType.value,
                onChanged: (val) {
                  controller.selectedAccountType.value = val!;
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIdUploadSection() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Government ID (Required):', style: TextStyle(fontWeight: FontWeight.bold)),
            AppGaps.hGap10,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please upload a valid government-issued ID document for verification.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  AppGaps.hGap10,
                  controller.governmentIdFile.value == null
                      ? ElevatedButton.icon(
                          onPressed: controller.pickGovernmentIdFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Select ID Document'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.orangeColor,
                            side: const BorderSide(color: AppColors.orangeColor),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.file_present,
                                        color: AppColors.orangeColor, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        controller.governmentIdFile.value!.name,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: controller.clearGovernmentIdFile,
                              icon: const Icon(Icons.close, color: Colors.red),
                              iconSize: 20,
                            ),
                          ],
                        ),
                  if (controller.governmentIdError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        controller.governmentIdError.value,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ));
  }
}
