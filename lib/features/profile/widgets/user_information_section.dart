import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/reusablewidgets/profile_section_icontextrow.dart';
import 'package:flutter/material.dart';

class UserInformationSection extends StatelessWidget {
  final UserInformation userInformationSection;
  final VoidCallback onSettingsPressed;

  const UserInformationSection({
    super.key,
    required this.userInformationSection,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Top Greeting Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${AppStrings.greeting}, ${AppStrings.profile_user_info_section_user}!",
              style: AppTextStyles.bodyText_profile_heading,
            ),
            GestureDetector(
              onTap: onSettingsPressed,
              child: Image.asset(
                AppImages.profile_settings,
                height: 35,
                width: 35,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        /// Profile Info Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  AppImages.profile_profileIcon,
                  height: 46.67,
                  width: 46.67,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userInformationSection.username,
                        style: AppTextStyles.bodyText_profile_heading2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                                (index) => Icon(
                              index < userInformationSection.rating
                                  ? Icons.star
                                  : Icons.star_border_outlined,
                              color: AppColors.profile_review,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '${userInformationSection.reviewsCount} ${AppStrings.profile_user_info_section_buyer_reviews}',
                          style: AppTextStyles.bodyText_profile_subheading,
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.greyTextColorTwo,
            ),
          ],
        ),
        const SizedBox(height: 20),

        /// Stats Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Info Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTextRow(
                  assetPath: AppImages.profile_followers,
                  text:
                  '${userInformationSection.followingCount} ${AppStrings.profile_user_info_section_following}, ${userInformationSection.followersCount} ${AppStrings.profile_user_info_section_followers}',
                ),
                IconTextRow(
                  assetPath: AppImages.profile_location,
                  text: userInformationSection.location,
                ),
                IconTextRow(
                  assetPath: AppImages.profile_email,
                  text: AppStrings.email,
                ),
                if (userInformationSection.hasBuyerDiscounts)
                  IconTextRow(
                    assetPath: AppImages.profile_discount,
                    text:
                    AppStrings.profile_user_info_section_buyer_discount,
                  ),
              ],
            ),

            /// Awards Column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppImages.profile_awards,
                  height: 23.33,
                  width: 36.66,
                ),
                const SizedBox(height: 4),
                Text(
                  "${userInformationSection.awards} ${AppStrings.profile_user_info_section_buyer_awards}",
                  style: AppTextStyles.bodyText_profile_subheading,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
