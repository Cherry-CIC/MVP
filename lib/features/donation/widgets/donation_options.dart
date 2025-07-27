import 'package:cherry_mvp/features/donation/widgets/donation_option.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class DonationOptions extends StatelessWidget {
  final bool isOpenToOtherCharity;
  final bool isOpenToOffer;
  final bool isApplicableBuyerDiscounts;
  final ValueChanged<bool> onOpenToOtherCharityChanged;
  final ValueChanged<bool> onOpenToOfferChanged;
  final ValueChanged<bool> onApplicableBuyerDiscountsChanged;

  const DonationOptions({
    super.key,
    required this.isOpenToOtherCharity,
    required this.onOpenToOtherCharityChanged,
    required this.isOpenToOffer,
    required this.onOpenToOfferChanged,
    required this.isApplicableBuyerDiscounts,
    required this.onApplicableBuyerDiscountsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(AppStrings.donationOptionsText),
          subtitle: Text(
              '${AppStrings.giveYourBuyerText}\n${AppStrings.easyWayText}'),
          subtitleTextStyle: Theme.of(context).textTheme.bodyMedium,
          textColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        ListTile(
          title: DonationOption(
            labelText: AppStrings.openToOtherCharitiesText,
            value: isOpenToOtherCharity,
            onChanged: onOpenToOtherCharityChanged,
          ),
        ),
        ListTile(
          title: DonationOption(
            labelText: AppStrings.openToOffersText,
            value: isOpenToOffer,
            onChanged: onOpenToOfferChanged,
          ),
        ),
        ListTile(
          title: DonationOption(
            labelText: AppStrings.applicableForBuyerDiscountsText,
            value: isApplicableBuyerDiscounts,
            onChanged: onApplicableBuyerDiscountsChanged,
          ),
        ),
      ],
    );
  }
}
