import 'package:flutter/material.dart';

class Constants {
  static const String appName = "Shop Now";
  static const double bottomSheetBorderRadiusValue = 40;
  static const int defaultUnsetDateTimeYear = 2000;
  static const double unsetMapLatLng = -999;
  static const String userRoleUser = 'user';

  static const String notificationChannelID = 'Shop Now';
  static const String notificationChannelName = 'Shop Now Notifications';
  static const String notificationChannelDescription =
      'Shop Now app notification channel';
  static const String notificationChannelTicker = 'shopnowsticker';

  static const double smallBorderRadiusValue = 5;

  static const double defaultBorderRadiusValue = 18;
  static const double borderRadiusValue = 28;

  /// Screen horizontal padding value
  static const double screenPaddingValue = 24;
  static const double bottomScreenSpaceValue = 30;
  static const double bottomSheetTopPaddingValue = 24;

  static const double uploadImageButtonBorderRadiusValue = 12;

  static const double dialogBorderRadiusValue = 20;
  // Dialog padding values
  static const double dialogVerticalSpaceValue = 16;
  static const double dialogHalfVerticalSpaceValue = 8;
  static const double dialogHorizontalSpaceValue = 18;
  static const double buttonBorderRadiusValue = 18;
  static const double imageBorderRadiusValue = 14;
  static const double auctionGridItemBorderRadiusValue = 20;

  static const String companyVatTypePercentage = 'percentage';
  static const String companyVatTypeFlat = 'flat';

  static const String unknown = 'unknown';

  static const String apiDateTimeFormatValue =
      'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'';

  static const String preferredDeliveryTimeFullDay = 'any_time';
  static const String preferredDeliveryTimeMorning = 'morning_shift';
  static const String preferredDeliveryTimeAfternoon = 'afternoon_shift';
  static const String savedAddressDeliveryTypeOffice = 'office';
  static const String savedAddressDeliveryTypeHome = 'home';
  static const String savedAddressDeliveryTypeOther = 'other';

  // My Orders Order statuses
  static const String myOrderStatusTypePlaced = 'placed';
  static const String myOrderStatusTypePending = 'pending';
  static const String myOrderStatusTypeConfirm = 'confirm';
  static const String myOrderStatusTypeProcessing = 'processing';
  static const String myOrderStatusTypePicked = 'approved';
  static const String myOrderStatusTypeOnWay = 'on_way';
  static const String myOrderStatusTypeDelivered = 'delivered';
  static const String myOrderStatusTypeCancelled = 'cancelled';

  // Notification types
  static const String notificationTypeOrder = 'order';
  static const String notificationTypeConfirmOrder = 'confirm_order';
  static const String notificationTypeDelivery = 'delivery';

  // Notification types statuses
  static const String notificationTypeStatusPlaced = myOrderStatusTypePlaced;
  static const String notificationTypeStatusPending = myOrderStatusTypePending;
  static const String notificationTypeStatusConfirm = myOrderStatusTypeConfirm;
  static const String notificationTypeStatusCancelled =
      myOrderStatusTypeCancelled;
  static const String notificationTypeStatusProcessing =
      myOrderStatusTypeProcessing;
  static const String notificationTypeStatusOnWay = myOrderStatusTypeOnWay;
  static const String notificationTypeStatusDelivered =
      myOrderStatusTypeDelivered;
  static const String notificationTypeStatusApproved =
      deliveryNotificationTypeStatusApproved;
  static const String notificationTypeStatusRejected =
      deliveryNotificationTypeStatusRejected;
  static const String notificationTypeStatusAccepted =
      deliveryNotificationTypeStatusAccepted;
  static const String notificationTypeStatusPicked =
      deliveryNotificationTypeStatusPicked;

  // Delivery notification statuses
  static const String deliveryNotificationTypeStatusPending = 'pending';
  static const String deliveryNotificationTypeStatusApproved = 'approved';
  static const String deliveryNotificationTypeStatusRejected = 'rejected';
  static const String deliveryNotificationTypeStatusAccepted = 'accepted';
  static const String deliveryNotificationTypeStatusPicked = 'picked';
  static const String deliveryNotificationTypeStatusOnWay = 'on_way';
  static const String deliveryNotificationTypeStatusDelivered = 'delivered';

  // Push notification types
  static const String pushNotificationTypeOrder = 'order';

  static const String userGenderMale = 'male';
  static const String userGenderFemale = 'female';

  static const String addressTypeSaveAddress = 'save_address';

  static const String addressTypePickup = 'pickup';
  static const String addressTypeMap = 'google_map';

  static const double defaultMapZoomLevel = 12.4746;
  // static const LatLng defaultMapLatLng =
  // LatLng(6.1296, 1.2197);
  // static const CameraPosition defaultMapCameraPosition = CameraPosition(
  //   target: defaultMapLatLng,
  //   zoom: defaultMapZoomLevel,
  // );

  static const String hiveBoxName = 'zero_one_supplies_user';
  /*Hive Box and Key Names*/
  static const String registrationTokenName = 'registrationTokenBox';
  static const String registrationTokenKey = 'registrationTokenKey';
  static const String hiveDefaultLanguageKey = 'default_language';
  static const String mealBool = 'isMeal';
  static const String mealKey = 'mealKey';
  /*Hive Box and Key Names*/
  static const String languageTranslationKeyCode = '_code';
  static const String fallbackLocale = 'en_US';
  static const String fallbackFrenchLocale = 'fr_FR';

  static const String otpOptionEmail = 'email';
  static const String otpOptionSMS = 'sms';

  // Product condition status
  static const String productConditionNew = 'new';
  static const String productConditionUsed = 'used';

  static BorderRadius borderRadius(double radiusValue) =>
      BorderRadius.all(Radius.circular(radiusValue));
}
