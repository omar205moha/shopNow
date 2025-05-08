import 'package:flutter/material.dart';
import 'package:shop_now_mobile/utils/helper.dart';

class AppColors {
  static const whiteColor = Color(0xFFFFFFFF);
  static const orangeColor = Color(0xFFFC6011);
  static const greyDark = Color(0xFF4A4B4D);
  static const greyLight = Color(0xFF7C7D7E);
  static const placeholder = Color(0xFFB6B7B7);
  static const placeholderBg = Color(0xFFF2F2F2);

  /* <------- Custom Color ------> */
  static const Color purpleColor = Color(0xFF7A63EC);
  static const Color purpleLightColor = Color.fromRGBO(122, 99, 236, 0.25);
  static const Color yellowColor = Color(0xFFF79C39);
  static const Color yellowLightColor = Color.fromRGBO(247, 156, 57, 0.25);
  static const Color blueSkyColor = Color(0xFF4BCBF9);
  static const Color blueSkyLightColor = Color.fromRGBO(75, 203, 249, 0.25);
  static const Color successColor = Color(0xFF48E98A);
  static const Color alertColor = Color(0xFFFE4651);
  static const Color darkColor = Color(0xFF292B49);
  static const Color bodyTextColor = Color(0xFF888AA0);
  static const Color lineShapeColor = Color(0xFFEBEDF9);
  static const Color shadeColor1 = Color(0xFFF4F5FA);
  static const Color shadeColor2 = Color(0xFFF7F7FB);
  static const Color backgroundColor = Colors.white;
  static const Color successBackgroundColor = Color(0xFFEEF9E8);
  static const Color alertBackgroundColor = Color(0xFFFFEDED);
  static const Color shimmerBaseColor = Color(0xFFCED7E2);
  static const Color shimmerHighlightColor = AppColors.lineShapeColor;

  /// Custom MaterialColor from Helper function
  static final MaterialColor primaryMaterialColor =
      Helper.generateMaterialColor(AppColors.orangeColor);
}
