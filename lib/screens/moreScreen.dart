import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_images.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/controllers/main_cart_controller.dart';
import 'package:shop_now_mobile/screens/aboutScreen.dart';
import 'package:shop_now_mobile/screens/inboxScreen.dart';
import 'package:shop_now_mobile/screens/myOrderScreen.dart';
import 'package:shop_now_mobile/screens/myOrdersScreen.dart';
import 'package:shop_now_mobile/screens/notificationScreen.dart';
import 'package:shop_now_mobile/screens/paymentScreen.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:shop_now_mobile/widgets/custom_nav_bar.dart';

class MoreScreen extends StatelessWidget {
  static const routeName = "/moreScreen";

  final MainCartController cartController = Get.find<MainCartController>();
  MoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              height: Helper.getScreenHeight(context),
              width: Helper.getScreenWidth(context),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "More",
                        style: Helper.getTheme(context).headlineLarge,
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
                  const SizedBox(
                    height: 20,
                  ),
                  /* MoreCard(
                    image: Image.asset(
                      Helper.getAssetName("income.png", "virtual"),
                    ),
                    name: "Payment Details",
                    handler: () {
                      Navigator.of(context).pushNamed(PaymentScreen.routeName);
                    },
                  ),*/
                  const SizedBox(
                    height: 10,
                  ),
                  MoreCard(
                    image: Image.asset(
                      Helper.getAssetName("shopping_bag.png", "virtual"),
                    ),
                    name: "My Orders",
                    handler: () {
                      Navigator.of(context).pushNamed(MyOrdersScreen.routeName);
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  MoreCard(
                    image: Image.asset(
                      Helper.getAssetName("noti.png", "virtual"),
                    ),
                    name: "Notifications",
                    isNoti: true,
                    handler: () {
                      Navigator.of(context).pushNamed(NotificationScreen.routeName);
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  /*   MoreCard(
                    image: Image.asset(
                      Helper.getAssetName("mail.png", "virtual"),
                    ),
                    name: "Inbox",
                    handler: () {
                      Navigator.of(context).pushNamed(InboxScreen.routeName);
                    },
                  ),*/
                  const SizedBox(
                    height: 10,
                  ),
                  MoreCard(
                    image: Image.asset(
                      Helper.getAssetName("info.png", "virtual"),
                    ),
                    name: "About Us",
                    handler: () {
                      Navigator.of(context).pushNamed(AboutScreen.routeName);
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  /*  MoreCard(
                    image: Image.asset(
                      AppAssetImages.dropdownPNG,
                    ),
                    name: "Order History",
                    handler: () {
                      // Navigator.of(context).pushNamed(AboutScreen.routeName);
                    },
                  ),*/
                  const SizedBox(
                    height: 10,
                  ),
                  /*  MoreCard(
                    image: Image.asset(
                      AppAssetImages.mailPNG,
                    ),
                    name: "Support",
                    handler: () {
                      // Navigator.of(context).pushNamed(AboutScreen.routeName);
                    },
                  ),*/
                  const SizedBox(
                    height: 10,
                  ),
                ]),
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            child: CustomNavBar(
              more: true,
            ),
          )
        ],
      ),
    );
  }
}

class MoreCard extends StatelessWidget {
  const MoreCard({
    super.key,
    required this.name,
    required this.image,
    this.isNoti,
    required this.handler,
  });

  final String name;
  final Image image;
  final bool? isNoti;
  final Function() handler;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handler,
      child: SizedBox(
        height: 70,
        width: double.infinity,
        child: Stack(
          children: [
            Container(
              height: double.infinity,
              width: double.infinity,
              margin: const EdgeInsets.only(
                right: 20,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                color: AppColors.placeholderBg,
              ),
              child: Row(
                children: [
                  Container(
                      width: 50,
                      height: 50,
                      decoration: ShapeDecoration(
                        shape: const CircleBorder(),
                        color: AppColors.primaryMaterialColor.shade200,
                      ),
                      child: image),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.greyDark,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                height: 30,
                width: 30,
                decoration: const ShapeDecoration(
                  shape: CircleBorder(),
                  color: AppColors.placeholderBg,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.greyLight,
                  size: 17,
                ),
              ),
            ),
            if (isNoti ?? false)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 20,
                  width: 20,
                  margin: const EdgeInsets.only(
                    right: 50,
                  ),
                  decoration: const ShapeDecoration(
                    shape: CircleBorder(),
                    color: Colors.red,
                  ),
                  child: const Center(
                    child: Text(
                      "15",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
