import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_gaps.dart';
import 'package:shop_now_mobile/utils/helper.dart';

class RecentItemCard extends StatelessWidget {
  final String name;
  final Image? image;
  final String? shopName;

  const RecentItemCard({
    super.key,
    required this.name,
    this.image,
    this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.0),
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 70,
              child: image ?? Container(color: AppColors.placeholderBg),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 10.0,
              children: [
                Text(
                  name,
                  style:
                      Helper.getTheme(context).headlineMedium?.copyWith(color: AppColors.greyDark),
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 5,
                    ),
                    Text(shopName ?? "Anonymous Shop"),
                    const SizedBox(
                      width: 20,
                    ),
                  ],
                ),
                /*   Row(
                  children: [
                    Image.asset(
                      Helper.getAssetName("star_filled.png", "virtual"),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    const Text(
                      "4.9",
                      style: TextStyle(
                        color: AppColors.orangeColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('(124) Ratings')
                  ],
                )
             */
              ],
            ),
          )
        ],
      ),
    );
  }
}

class MostPopularCard extends StatelessWidget {
  final String name;
  final Image? image;

  const MostPopularCard({
    super.key,
    required this.name,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 300,
            height: 200,
            child: image ?? Container(color: AppColors.placeholderBg),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: Helper.getTheme(context).headlineMedium?.copyWith(color: AppColors.greyDark),
        ),
        Row(
          children: [
            const Text("Cafe"),
            const SizedBox(
              width: 5,
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 5.0),
              child: Text(
                ".",
                style: TextStyle(
                  color: AppColors.orangeColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            const Text("Western Food"),
            const SizedBox(
              width: 20,
            ),
            Image.asset(
              Helper.getAssetName("star_filled.png", "virtual"),
            ),
            const SizedBox(
              width: 5,
            ),
            const Text(
              "4.9",
              style: TextStyle(
                color: AppColors.orangeColor,
              ),
            )
          ],
        )
      ],
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final String name;
  final Image? image;

  const RestaurantCard({
    super.key,
    required this.name,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      height: 270,
      width: 300,
      child: Column(
        children: [
          SizedBox(
              height: 200,
              width: double.infinity,
              child: image ?? Container(color: AppColors.placeholderBg)),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: Helper.getTheme(context).headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                /*   Row(
                  children: [
                    Image.asset(
                      Helper.getAssetName("star_filled.png", "virtual"),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    const Text(
                      "4.9",
                      style: TextStyle(
                        color: AppColors.orangeColor,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    const Text("(124 ratings)"),
                    const SizedBox(
                      width: 5,
                    ),
                    const Text("Cafe"),
                    const SizedBox(
                      width: 5,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5.0),
                      child: Text(
                        ".",
                        style: TextStyle(
                          color: AppColors.orangeColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    const Text("Western Food"),
                  ],
                ),
              */
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String name;
  final Image? image;

  const CategoryCard({
    super.key,
    required this.name,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 100,
            height: 100,
            child: image ?? Container(color: AppColors.placeholderBg),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          name,
          style: Helper.getTheme(context)
              .headlineMedium
              ?.copyWith(color: AppColors.greyDark, fontSize: 16),
        ),
      ],
    );
  }
}

class BrandCard extends StatelessWidget {
  final String name;
  final SvgPicture? image;

  const BrandCard({
    super.key,
    required this.name,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Container(
            color: AppColors.placeholderBg,
            width: 70,
            height: 70,
            child: image ?? Container(color: AppColors.placeholderBg),
          ),
        ),
        AppGaps.hGap5,
        Text(
          name,
          style: Helper.getTheme(context)
              .headlineMedium
              ?.copyWith(color: AppColors.greyDark, fontSize: 16),
        ),
      ],
    );
  }
}
