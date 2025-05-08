import 'package:flutter/material.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/screens/homeScreen.dart';
import 'package:shop_now_mobile/screens/landingScreen.dart';
import 'package:shop_now_mobile/screens/login_screen.dart';
import 'package:shop_now_mobile/utils/helper.dart';

class IntroScreens extends StatefulWidget {
  static const routeName = "/introScreen";

  const IntroScreens({super.key});

  @override
  _IntroScreensState createState() => _IntroScreensState();
}

class _IntroScreensState extends State<IntroScreens> {
  var _controller;
  int count = 0;
  final List<Map<String, String>> _pages = [
    {
      "image": "vector1.png",
      "title": "Find Items You Love",
      "desc":
          "Discover the best items from over 1,000 shops and fast delivery to your doorstep"
    },
    {
      "image": "vector2.png",
      "title": "Fast Delivery",
      "desc": "Fast item delivery to your home, office wherever you are"
    },
    {
      "image": "vector3.png",
      "title": "Live Tracking",
      "desc":
          "Real time tracking of your item on the app once you placed the order"
    },
  ];

  @override
  void initState() {
    _controller = new PageController();
    count = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: Helper.getScreenWidth(context),
        height: Helper.getScreenHeight(context),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Spacer(),
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (value) {
                      setState(() {
                        count = value;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.asset(Helper.getAssetName(
                          _pages[index]["image"] ?? "Null image", "virtual"));
                    },
                    itemCount: _pages.length,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 5,
                      backgroundColor: count == 0
                          ? AppColors.orangeColor
                          : AppColors.placeholder,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    CircleAvatar(
                      radius: 5,
                      backgroundColor: count == 1
                          ? AppColors.orangeColor
                          : AppColors.placeholder,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    CircleAvatar(
                      radius: 5,
                      backgroundColor: count == 2
                          ? AppColors.orangeColor
                          : AppColors.placeholder,
                    )
                  ],
                ),
                Spacer(),
                Text(
                  _pages[count]["title"] ?? "Null title",
                  style: Helper.getTheme(context).headlineLarge,
                ),
                Spacer(),
                Text(
                  _pages[count]["desc"] ?? "Null description",
                  textAlign: TextAlign.center,
                ),
                Spacer(),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(LandingScreen.routeName);
                      },
                      child: Text("Next",
                          style: Helper.getTheme(context)
                              .bodyLarge
                              ?.copyWith(color: AppColors.whiteColor))),
                ),
                Spacer()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
