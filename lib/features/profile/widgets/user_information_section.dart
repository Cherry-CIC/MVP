import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/widgets/profile_section_icontextrow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_view_model.dart';

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
    return Consumer<AuthViewModel>(
      builder: (context, auth, _) {
        final name =
            auth.userCredentials?.firstname ?? auth.userCredentials?.email;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Greeting Row
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "${AppStrings.greeting}${name != null && name.isNotEmpty ? ', $name' : ''}!",
              ),
              titleTextStyle: Theme.of(context).textTheme.titleLarge,
              trailing: IconButton(
                onPressed: onSettingsPressed,
                icon: Icon(Icons.settings),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Image.asset(
                AppImages.profileProfileIcon,
                height: 48,
                width: 48,
              ),
              title: Text(name ?? ""),
              titleTextStyle: Theme.of(context).textTheme.titleSmall,
              subtitle: Row(
                spacing: 16,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < userInformationSection.rating
                            ? Icons.star
                            : Icons.star_border_outlined,
                        color: AppColors.yellow,
                      ),
                    ),
                  ),
                  Text(
                    '${userInformationSection.reviewsCount} ${AppStrings.profileUserInfoSectionBuyerReviews}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
                      assetPath: AppImages.profileFollowers,
                      text:
                          '${userInformationSection.followingCount} ${AppStrings.profileUserInfoSectionFollowing}, ${userInformationSection.followersCount} ${AppStrings.profileUserInfoSectionFollowers}',
                    ),
                    IconTextRow(
                      assetPath: AppImages.profileLocation,
                      text: userInformationSection.location,
                    ),
                    IconTextRow(
                      assetPath: AppImages.profileemail,
                      text: AppStrings.email,
                    ),
                    if (userInformationSection.hasBuyerDiscounts)
                      IconTextRow(
                        assetPath: AppImages.profileDiscount,
                        text: AppStrings.profileUserInfoSectionBuyerDiscount,
                      ),
                  ],
                ),

                /// Awards Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AppImages.profileAwards, height: 32, width: 32),
                    const SizedBox(height: 4),
                    Text(
                      "${userInformationSection.awards} ${AppStrings.profileUserInfoSectionBuyerAwards}",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
