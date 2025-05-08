import 'package:flutter/material.dart';
import 'package:shop_now_mobile/const/app_images.dart';

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
                image: Image.asset(AppAssetImages.shoppingBagPNG).image,
                fit: BoxFit.fill)),
        child: const SafeArea(
          child: Center(
            child: Text('Unknown Screen'),
          ),
        ),
      ),
    );
  }
}
