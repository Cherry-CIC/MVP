import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/profile/widgets/info_row.dart';
 
class UserInformationSection extends StatelessWidget {
  final String username;
  final String location;
  final int reviewsCount;
  final int followersCount;
  final int followingCount;
  final double rating;
  final int awards;
  final bool hasBuyerDiscounts;

  const UserInformationSection({
    super.key,
    required this.username,
    required this.awards,
    required this.location,
    required this.reviewsCount,
    required this.followersCount,
    required this.followingCount,
    required this.rating,
    this.hasBuyerDiscounts = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom:16.0), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${AppStrings.greeting}, ${AppStrings.profile_user_info_section_user}!",
                style: AppTextStyles.bodyText_profile_heading,
              ),
              Image.asset(
                AppImages.profile_settings,
                height: 35,
                width: 35,
              ),
            ],
          )
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom:12.0, right:10.0), 
                  child: Image.asset(
                    AppImages.profile_profileIcon,
                    height: 46.67,
                    width: 46.67,
                  )
                ), 

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username,
                        style: AppTextStyles.bodyText_profile_heading2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: 
                                List.generate(5, (index) => 
                                  Icon(
                                    index < rating.round()
                                      ? Icons.star
                                      : Icons.star_border_outlined,
                                    color: AppColors.profile_review,
                                    size: 20,
                                  ),
                                ), 
                            ),

                            Padding(
                              padding: EdgeInsets.only(left:10.0), 
                              child: Text(
                                '$reviewsCount ${AppStrings.profile_user_info_section_buyer_reviews}',
                                style: AppTextStyles.bodyText_profile_subheading
                              )
                            ) 
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.greyTextColorTwo),
          ],
        ), 

        Padding(
          padding: EdgeInsets.symmetric(vertical:20.0), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,  
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        AppImages.profile_followers,
                        height: 16,
                        width: 16,
                      ), 

                      Padding(
                        padding: EdgeInsets.only(left:8.0), 
                        child: Text(
                          '$followingCount ${AppStrings.profile_user_info_section_following}, $followersCount ${AppStrings.profile_user_info_section_followers}',
                          style: AppTextStyles.bodyText_profile_subheading
                        )
                      ),
                    ],
                  ), 

                  Padding(
                    padding: EdgeInsets.only(top:8.0), 
                    child: InfoRow(text: location, iconPath: AppImages.profile_location)
                  ), 

                  Padding(
                    padding: EdgeInsets.only(top:8.0), 
                    child: InfoRow(text: AppStrings.email, iconPath: AppImages.profile_email)
                  ),
 
                  if (hasBuyerDiscounts)    
                    Padding(
                      padding: EdgeInsets.only(top:8.0), 
                      child: InfoRow(text: AppStrings.profile_user_info_section_buyer_discount, iconPath: AppImages.profile_discount)
                    ),
                ],
              ),
              
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppImages.profile_awards,
                    height: 23.33,
                    width: 36.66,
                  ), 

                  Padding(
                    padding: EdgeInsets.only(top:4.0), 
                    child: Text(
                      "$awards ${AppStrings.profile_user_info_section_buyer_awards}",
                      style: AppTextStyles.bodyText_profile_subheading
                    )
                  )
                ],
              ),
            ],
          )
        ) 
      ],
    );
  }
}