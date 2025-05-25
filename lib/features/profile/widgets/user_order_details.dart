import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/reusablewidgets/profile_user_order_details.dart';
import 'package:flutter/material.dart';

class UserOrderDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              UserOrderTile(
                  title: AppStrings.profile_user_orders,
                  onPressed: () {},
                  assetPath: AppImages.profile_order),
              UserOrderTile(
                  title: AppStrings.profile_user_liked,
                  onPressed: () {},
                  assetPath: AppImages.profile_liked),
              UserOrderTile(
                  title: AppStrings.profile_user_listings,
                  onPressed: () {},
                  assetPath: AppImages.profile_listings),
            ],
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(10.0),
          width: double.infinity,
          height: 41,
          decoration: BoxDecoration(
            color: AppColors.lightGreyFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.profile_user_Buyer_disc,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greyTextColorTwo,
                ),
              ),
              Image.asset(
                AppImages.profile_discount,
                color: AppColors.piechart_red,
                height: 18,
                width: 18,
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
