import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';

/// A compact status strip, with next steps on the seller's full product page.
class SoldListingBanner extends StatelessWidget {
  const SoldListingBanner({super.key, this.showSellerMessage = false});

  final bool showSellerMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.soldGreen,
      padding: EdgeInsets.all(showSellerMessage ? 16 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.productSold,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showSellerMessage) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.productSoldCongratulations,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.productSoldNextSteps,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
