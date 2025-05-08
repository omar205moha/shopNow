import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/controllers/splash_screen_controller.dart';
import '../utils/helper.dart';

class SplashScreen extends StatelessWidget {
  static const routeName = "/splashScreen";
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: SplashScreenController(),
        global: false,
        builder: (controller) {
          return Scaffold(
            body: SizedBox(
              width: Helper.getScreenWidth(context),
              height: Helper.getScreenHeight(context),
              child: Stack(
                children: [
                  SizedBox(
                    height: double.infinity,
                    width: double.infinity,
                    child: Image.asset(
                      Helper.getAssetName("splashIcon.png", "virtual"),
                      fit: BoxFit.fill,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      Helper.getAssetName("ShopNowLogo.png", "virtual"),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
