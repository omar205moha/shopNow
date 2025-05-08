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

class InboxScreen extends StatelessWidget {
  static const routeName = "/inboxScreen";

  final MainCartController cartController = Get.find<MainCartController>();
  InboxScreen({super.key});
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
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                      ),
                      Expanded(
                        child: Text(
                          "Inbox",
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
                  height: 30,
                ),
                const Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        MailCard(
                          title: "ShopNow Promotions",
                          description:
                              "Lorem Ipsum dolor sit amet,consectetur adipiscing elit, sed do eiusmod tempor ",
                          time: "6th July",
                        ),
                        MailCard(
                          title: "ShopNow Promotions",
                          description:
                              "Lorem Ipsum dolor sit amet,consectetur adipiscing elit, sed do eiusmod tempor ",
                          time: "6th July",
                          color: AppColors.placeholderBg,
                        ),
                        MailCard(
                          title: "ShopNow Promotions",
                          description:
                              "Lorem Ipsum dolor sit amet,consectetur adipiscing elit, sed do eiusmod tempor ",
                          time: "6th July",
                        ),
                        MailCard(
                          title: "ShopNow Promotions",
                          description:
                              "Lorem Ipsum dolor sit amet,consectetur adipiscing elit, sed do eiusmod tempor ",
                          time: "6th July",
                          color: AppColors.placeholderBg,
                        ),
                        MailCard(
                          title: "ShopNow Promotions",
                          description:
                              "Lorem Ipsum dolor sit amet,consectetur adipiscing elit, sed do eiusmod tempor ",
                          time: "6th July",
                        ),
                        MailCard(
                          title: "ShopNow Promotions",
                          description:
                              "Lorem Ipsum dolor sit amet,consectetur adipiscing elit, sed do eiusmod tempor ",
                          time: "6th July",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            child: CustomNavBar(
              menu: true,
            ),
          ),
        ],
      ),
    );
  }
}

class MailCard extends StatelessWidget {
  final String time;
  final String title;
  final String description;
  final Color? color;

  const MailCard({
    super.key,
    required this.time,
    required this.title,
    required this.description,
    this.color,
  });

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
              SvgPicture.asset(AppAssetImages.messageSVGLogoLine),
            ],
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.greyDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(description),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                ),
              ),
              Image.asset(Helper.getAssetName("star.png", "virtual"))
            ],
          ),
        ],
      ),
    );
  }
}
