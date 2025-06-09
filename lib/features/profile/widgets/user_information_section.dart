import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/reusablewidgets/profile_section_icontextrow.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserInformationSection extends StatelessWidget {
  final UserInformation userInformationSection;

  const UserInformationSection({
    super.key,
    required this.userInformationSection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${AppStrings.greeting}, ${AppStrings.profile_user_info_section_user}!",
              style: AppTextStyles.bodyText_profile_heading,
            ),
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/profile/settings'),
              icon: Image.asset(AppImages.profile_settings,
                  height: 32, width: 32),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                style:
                                    AppTextStyles.bodyText_profile_subheading),
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
        SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
          children: [
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
                    text: userInformationSection.location),
                IconTextRow(
                    assetPath: AppImages.profile_email, text: AppStrings.email),
                if (userInformationSection.hasBuyerDiscounts)
                  if (userInformationSection.hasBuyerDiscounts)
                    IconTextRow(
                        assetPath: AppImages.profile_discount,
                        text:
                            "${AppStrings.profile_user_info_section_buyer_discount}")
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
                SizedBox(height: 4),
                Text(
                    "${userInformationSection.awards} ${AppStrings.profile_user_info_section_buyer_awards}",
                    style: AppTextStyles.bodyText_profile_subheading),
              ],
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
