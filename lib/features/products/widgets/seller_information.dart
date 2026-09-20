import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/feature_flags.dart';
import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/widgets/star_rating.dart';

class SellerInformation extends StatelessWidget {
  final UserInformation user;
  final ImageProvider<Object>? profileImage;
  final Widget charity;
  final EdgeInsets? padding;
  final VoidCallback? onAskSeller;
  final VoidCallback? onViewProfile;

  const SellerInformation({
    super.key,
    required this.user,
    this.profileImage,
    required this.charity,
    this.padding,
    this.onAskSeller,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            flex: 5,
            child: Semantics(
              button: onViewProfile != null,
              label: onViewProfile == null ? user.username : 'View ${user.username}’s public profile',
              child: InkWell(
                key: const ValueKey('seller-public-profile'),
                onTap: onViewProfile,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                  child: Row(
                    spacing: 8,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage(AppImages.icProfile),
                        foregroundImage: profileImage,
                        onForegroundImageError: profileImage == null ? null : (_, _) {},
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExcludeSemantics(
                              child: Text(
                                user.username,
                                style: const TextStyle(height: 1, fontSize: 14),
                              ),
                            ),
                            if (FeatureFlags.showRatings)
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  StarRating(userInformation: user, starSize: 12),
                                  Text(
                                    '(${user.reviewsCount})',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (charity is Image)
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(150),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(width: 42, height: 42, child: charity),
            ),
          if (FeatureFlags.showAskSeller)
            Expanded(
              flex: 3,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  shape: StadiumBorder(),
                ),
                onPressed: onAskSeller,
                child: Text(AppStrings.askSeller, textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}
