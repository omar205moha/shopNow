import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_components.dart';
import 'package:shop_now_mobile/const/app_constants.dart';
import 'package:shop_now_mobile/const/app_gaps.dart';
import 'package:shop_now_mobile/const/app_text_styles.dart';
import 'package:shop_now_mobile/widgets/core_widgets.dart';

class AppDialogs {
  static Future<Object?> showSuccessDialog({String? titleText, required String messageText}) async {
    final String dialogTitle = titleText ?? 'Success';
    return Get.showSnackbar(
      GetSnackBar(
        margin: AppComponents.dialogActionPadding,
        borderRadius: Constants.borderRadiusValue,
        title: dialogTitle,
        message: messageText,
        backgroundColor: AppColors.successColor,
        icon: const Icon(
          Icons.done,
          color: AppColors.backgroundColor,
        ),
        snackPosition: SnackPosition.TOP,
        duration: 3.seconds,
      ),
    );
  }

  static Future<Object?> showErrorDialog({String? titleText, required String messageText}) async {
    final String dialogTitle = titleText ?? 'Sorry, something went wrong';
    return Get.showSnackbar(
      GetSnackBar(
        margin: AppComponents.dialogActionPadding,
        borderRadius: Constants.borderRadiusValue,
        title: dialogTitle,
        message: messageText,
        backgroundColor: AppColors.alertColor,
        icon: const Icon(
          Icons.error,
          color: AppColors.backgroundColor,
        ),
        snackPosition: SnackPosition.TOP,
        duration: 3.seconds,
      ),
    );
  }

  static Future<Object?> showProcessingDialog({String? message}) async {
    return await Get.dialog(
      AlertDialogWidget(
        titleWidget: Text(
          message ?? 'Processing',
          style: AppTextStyles.headlineLargeBoldTextStyle,
          textAlign: TextAlign.center,
        ),
        contentWidget: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            AppGaps.hGap16,
            Text('Please wait'),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  static Future<Object?> showConfirmDialog({
    String? titleText,
    required String messageText,
    required Future<void> Function() onYesTap,
    void Function()? onNoTap,
    bool shouldCloseDialogOnceYesTapped = true,
    String? yesButtonText,
    String? noButtonText,
  }) async {
    return await Get.dialog(AlertDialogWidget(
      titleWidget: Text(titleText ?? 'Confirm',
          style: AppTextStyles.titleSmallSemiboldTextStyle, textAlign: TextAlign.center),
      contentWidget: Text(messageText,
          textAlign: TextAlign.center, style: AppTextStyles.bodyLargeSemiboldTextStyle),
      actionWidgets: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onNoTap ??
                    () {
                      Get.back();
                    },
                child: Text(
                  noButtonText ?? 'No',
                  style: AppTextStyles.bodyLargeSemiboldTextStyle,
                ),
              ),
            ),
            AppGaps.wGap12,
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  await onYesTap();
                  if (shouldCloseDialogOnceYesTapped) Get.back();
                },
                child: Text(
                  yesButtonText ?? 'Yes',
                  style: AppTextStyles.bodyLargeSemiboldTextStyle,
                ),
              ),
            ),
          ],
        )
      ],
    ));
  }

  static Future<Object?> showActionableDialog(
      {String? titleText,
      required String messageText,
      Color titleTextColor = AppColors.alertColor,
      String? buttonText,
      void Function()? onTap}) async {
    return await Get.dialog(AlertDialogWidget(
      backgroundColor: AppColors.alertBackgroundColor,
      titleWidget: Text(titleText ?? 'Error',
          style: AppTextStyles.titleSmallSemiboldTextStyle.copyWith(color: titleTextColor),
          textAlign: TextAlign.center),
      contentWidget: Text(messageText,
          textAlign: TextAlign.center, style: AppTextStyles.bodyLargeSemiboldTextStyle),
      actionWidgets: [
        CustomStretchedTextButtonWidget(
          buttonText: buttonText ?? 'Ok',
          // backgroundColor: AppColors.alertColor,
          onTap: onTap,
        )
      ],
    ));
  }

  static Future<Object?> showImageProcessingDialog() async {
    return await Get.dialog(
        const AlertDialogWidget(
          titleWidget: Text('Image Processing',
              style: AppTextStyles.headlineLargeBoldTextStyle, textAlign: TextAlign.center),
          contentWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              AppGaps.hGap16,
              Text(
                'Please wait',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        barrierDismissible: false);
  }
}
