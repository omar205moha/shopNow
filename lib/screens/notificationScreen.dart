import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_gaps.dart';
import 'package:shop_now_mobile/const/app_images.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/controllers/main_cart_controller.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:shop_now_mobile/widgets/custom_nav_bar.dart';

class NotificationScreen extends StatelessWidget {
  static const routeName = "/notiScreen";

  final MainCartController cartController = Get.find<MainCartController>();

  NotificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
              child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Notifications",
                        style: Helper.getTheme(context).headlineLarge,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Get.toNamed(AppPageNames.myOrderScreen);
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Image.asset(
                              Helper.getAssetName("cart.png", "virtual"),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Obx(() => cartController.cartItems.isNotEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.orangeColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${cartController.cartItems.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : const SizedBox()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      NotiCard(
                        title: "Your order has been picked up",
                        time: "Now",
                      ),
                      NotiCard(
                        title: "Your order has been delivered",
                        time: "1 h ago",
                        color: AppColors.placeholderBg,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
          const Positioned(
              bottom: 0,
              left: 0,
              child: CustomNavBar(
                menu: true,
              ))
        ],
      ),
    );
  }
}

class NotiCard extends StatelessWidget {
  const NotiCard({
    super.key,
    required this.time,
    required this.title,
    this.color,
  });

  final String time;
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: AppColors.placeholder,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.orangeColor,
                radius: 5,
              ),
              AppGaps.hGap8,
              SvgPicture.asset(AppAssetImages.notificationSVGLogoLine),
            ],
          ),
          const SizedBox(
            width: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.greyDark,
                ),
              ),
              Text(time),
            ],
          )
        ],
      ),
    );
  }
}
