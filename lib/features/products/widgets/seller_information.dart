import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:flutter/material.dart';

class SellerInformation extends StatelessWidget {
  final UserInformation user;
  final ImageProvider<Object>? profileImage;
  final Widget charity;
  final EdgeInsets? padding;
  final VoidCallback? onAskSeller;

  const SellerInformation({
    super.key,
    required this.user,
    this.profileImage,
    required this.charity,
    this.padding,
    this.onAskSeller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Row(
              spacing: 8,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage(AppImages.icProfile),
                  foregroundImage: profileImage,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username,
                        style: TextStyle(height: 1, fontSize: 14)),
                    Row(
                      children: [
                        for (var i = 0; i < user.rating.floor(); i++)
                          Icon(Icons.star,
                              color: AppColors.profile_review, size: 12),
                        if (user.rating.ceil() != user.rating.floor())
                          Icon(Icons.star_half,
                              color: AppColors.profile_review, size: 12),
                        for (var i = 0; i < 5 - user.rating.ceil(); i++)
                          Icon(Icons.star_border,
                              color: AppColors.profile_review, size: 12),
                        SizedBox(width: 4),
                        Text(
                          '(${user.reviewsCount})',
                          style: Theme.of(context).textTheme.labelSmall,
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          Material(
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            elevation: 4,
            child: SizedBox(
              height: 48,
              width: 48,
              child: charity,
            ),
          ),
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    shape: StadiumBorder(),
                  ),
                  onPressed: onAskSeller,
                  child: Text('Ask seller')),
            ],
          )),
        ],
      ),
    );
  }
}
