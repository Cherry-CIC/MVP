import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/features/discover/widgets/product_image_card_discover.dart';
import 'package:cherry_mvp/features/home/widgets/product_image_card.dart';
import 'package:flutter/material.dart';

const dummyProducts = [
  {
    "imagePath": AppImages.product1,
    "likes": 3
  },
  {
    "imagePath": AppImages.product2,
    "likes": 2
  },
  {
    "imagePath": AppImages.product3,
    "likes": 4
  },
  {
    "imagePath": AppImages.product4,
    "likes": 1
  },
  {
    "imagePath": AppImages.product5,
    "likes": 3
  },
  {
    "imagePath": AppImages.product6,
    "likes": 3
  },
];

class ItemsInSupport extends StatelessWidget {
  const ItemsInSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyBgColor,
        borderRadius: BorderRadius.circular(10)
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(5, 10, 5, 5),
    child: Column(
        children: [
          Row(
            children: [
              Text(AppStrings.itemsInSupportText, style: AppTextStyles.screen_title,),
              Spacer(),
              Text(AppStrings.seeAllText, style: AppTextStyles.charityBodyText,)
            ],
          ),
          SizedBox(height: 5),
          SizedBox(
            height: 100, // Adjust the height as needed
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(width: 5,);
              },
              scrollDirection: Axis.horizontal,
              itemCount: dummyProducts.length,
              itemBuilder: (context, index) {
                return ProductImageCard(
                  imagePath: dummyProducts[index]["imagePath"] as String,
                  likes: dummyProducts[index]["likes"] as int,
                );
              },
            ),
          ),
        ],
      ),
      )
    );
  }
}
