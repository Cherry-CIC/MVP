import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class DiscoverCharityCard extends StatelessWidget {
  const DiscoverCharityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Image.asset(AppImages.discover_image1),
            Positioned(
              width: 50,
              height: 40,
              bottom: 5,
              left: 5,
              child: Image.asset(AppImages.waterAid_logo),
            ),
            Positioned(
                width: 35,
                height: 25,
                bottom: 9,
                right: 9,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColors.lightGreyFill,
                  ),
                  child: Row(
                    children: [
                      Image.asset(AppImages.likeHeart, width: 15, height: 11),
                      SizedBox(width: 5),
                      Text("3")
                    ],
                  ),
                ))
          ],
        ),
        SizedBox(height: 9),
        Text("WaterAid", style: AppTextStyles.charityHeadingText),
        Text(
            "In a small village in Malawi, WaterAid recently completed the construction of a new well, providing clean, safe drinking water to hundreds of residents. No more long treks for water. No more toxic sources!",
            style: AppTextStyles.charityBodyText)
      ],
    );
  }
}
