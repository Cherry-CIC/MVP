import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/widgets/profile_user_order_details.dart';
import 'package:flutter/material.dart';

class UserOrderDetails extends StatelessWidget {
  const UserOrderDetails({
    super.key,
    this.showLikedShortcut = false,
    this.onLikedPressed,
  });

  final bool showLikedShortcut;
  final VoidCallback? onLikedPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (FeatureFlags.showProfileStats || showLikedShortcut)
          SizedBox(
            height: 96,
            child: Row(
              children: [
                if (FeatureFlags.showProfileStats)
                  Expanded(
                    child: UserOrderTile(
                      title: AppStrings.profileUserOrders,
                      onPressed: () {},
                      assetPath: AppImages.profileOrder,
                    ),
                  ),
                if (FeatureFlags.showProfileStats && showLikedShortcut) SizedBox(width: 8),
                if (showLikedShortcut)
                  Expanded(
                    child: UserOrderTile(
                      title: AppStrings.profileUserLiked,
                      onPressed: onLikedPressed ?? () {},
                      assetPath: AppImages.profileLiked,
                    ),
                  ),
                if (FeatureFlags.showProfileStats) SizedBox(width: 8),
                if (FeatureFlags.showProfileStats)
                  Expanded(
                    child: UserOrderTile(
                      title: AppStrings.profileUserListings,
                      onPressed: () {},
                      assetPath: AppImages.profileListings,
                    ),
                  ),
              ],
            ),
          ),
        if (FeatureFlags.showDonorDiscounts) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    AppStrings.profileUserBuyerDisc,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Image.asset(
                  AppImages.profileDiscount,
                  color: Theme.of(context).colorScheme.primary,
                  height: 18,
                  width: 18,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
