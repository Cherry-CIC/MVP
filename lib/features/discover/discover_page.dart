import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_charity_card.dart';
import 'package:cherry_mvp/features/discover/widgets/discover_selection_bar.dart';
import 'package:cherry_mvp/features/discover/widgets/items_in_support.dart';
import 'package:flutter/material.dart';

const dummyCharity = {
  "title": "WaterAid",
  "description":
      "In a small village in Malawi, WaterAid recently completed the construction of a new well, providing clean, safe drinking water to hundreds of residents. No more long treks for water. No more toxic sources!",
  "imagePath": AppImages.discover_image1,
  "logoPath": AppImages.waterAid_logo,
  "likes": 3
};

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            DiscoverSelectionBar(),
            SizedBox(height: 30,),
            DiscoverCharityCard(
              title: dummyCharity["title"] as String,
              description: dummyCharity["description"] as String,
              imagePath: dummyCharity["imagePath"] as String,
              logoPath: dummyCharity["logoPath"] as String,
              likes: dummyCharity["likes"] as int,
            ),
            SizedBox(
              height: 30,
            ),
            ItemsInSupport(),
          ],
        ),
      ),
    );
  }
}
