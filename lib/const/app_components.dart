import 'package:flutter/material.dart';
import 'package:shop_now_mobile/const/app_constants.dart';
import 'package:intl/intl.dart';

/// This file contains various components for the app
class AppComponents {
  static const defaultBorderRadius = Radius.circular(18);
  static final DateTime defaultUnsetDateTime =
      DateTime(Constants.defaultUnsetDateTimeYear);
  static const defaultBorder = BorderRadius.all(Radius.circular(18));
  static const imageBorder =
      BorderRadius.all(Radius.circular(Constants.imageBorderRadiusValue));
  static const BorderRadius bottomSheetBorderRadius = BorderRadius.vertical(
      top: Radius.circular(Constants.bottomSheetBorderRadiusValue));

  static const BorderRadius dialogBorderRadius =
      BorderRadius.all(Radius.circular(Constants.dialogBorderRadiusValue));

  static const BorderRadius smallBorderRadius =
      BorderRadius.all(Radius.circular(Constants.smallBorderRadiusValue));

  static const BorderRadius imageBorderRadius =
      BorderRadius.all(Radius.circular(Constants.imageBorderRadiusValue));
  static final apiDateTimeFormat = DateFormat(Constants.apiDateTimeFormatValue);
  static const BorderRadius productGridItemBorderRadius = BorderRadius.all(
      Radius.circular(Constants.auctionGridItemBorderRadiusValue));
  static NumberFormat defaultNumberFormat =
      NumberFormat.currency(locale: 'fr_FR');
  // NumberFormat.currency(symbol: r'$', decimalDigits: 0);
  static const EdgeInsets dialogTitlePadding = EdgeInsets.fromLTRB(
      Constants.dialogHorizontalSpaceValue,
      Constants.dialogVerticalSpaceValue,
      Constants.dialogHorizontalSpaceValue,
      Constants.dialogVerticalSpaceValue);
  static const EdgeInsets dialogContentPadding = EdgeInsets.fromLTRB(
      Constants.dialogHorizontalSpaceValue,
      Constants.dialogHalfVerticalSpaceValue,
      Constants.dialogHorizontalSpaceValue,
      Constants.dialogVerticalSpaceValue);
  static const EdgeInsets dialogActionPadding = EdgeInsets.fromLTRB(
      Constants.dialogHorizontalSpaceValue,
      Constants.dialogVerticalSpaceValue,
      Constants.dialogHorizontalSpaceValue,
      Constants.dialogVerticalSpaceValue);
  static const EdgeInsets screenHorizontalPadding =
      EdgeInsets.symmetric(horizontal: Constants.screenPaddingValue);

  static BorderRadius borderRadius(double radius) =>
      BorderRadius.all(Radius.circular(radius));
}
