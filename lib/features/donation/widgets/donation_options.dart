import 'package:flutter/material.dart';   
import 'package:flutter/cupertino.dart';
import 'package:cherry_mvp/core/config/config.dart';  
import 'package:cherry_mvp/features/donation/widgets/toggle_item.dart'; 
 

class DonationOptions extends StatelessWidget { 

  const DonationOptions({
    super.key,
    required this.isSwitchedOpenToOtherCharity,
    required this.toggleSwitchOpenToOtherCharity,

    required this.isSwitchedOpenToOffer,
    required this.toggleSwitchOpenToOffer,

    required this.isSwitchedApplicableBuyerDiscounts,
    required this.toggleSwitchApplicableBuyerDiscounts,
  });   

  final bool isSwitchedOpenToOtherCharity;
  final void Function(bool)? toggleSwitchOpenToOtherCharity; 

  final bool isSwitchedOpenToOffer;
  final void Function(bool)? toggleSwitchOpenToOffer; 

  final bool isSwitchedApplicableBuyerDiscounts;
  final void Function(bool)? toggleSwitchApplicableBuyerDiscounts; 


 
  @override 
  Widget build(BuildContext context) {     

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [ 
        Text(
          AppStrings.donation_options_Text,
          style: TextStyle(fontSize: 15, color: AppColors.greyTextColor, fontWeight: FontWeight.w300,),
        ),   

        Text(
          AppStrings.give_your_buyer_Text,
          style: TextStyle(fontSize: 13, color: AppColors.greyTextColor, fontWeight: FontWeight.w300,),
        ),     
        
        Text(
          AppStrings.easy_way_Text,
          style: TextStyle(fontSize: 13, color: AppColors.greyTextColor, fontWeight: FontWeight.w300,),
        ),   
 
        ToggleItem(label: AppStrings.open_to_other_charities_Text, value: isSwitchedOpenToOtherCharity, onChanged: toggleSwitchOpenToOtherCharity),
        
        ToggleItem(label: AppStrings.open_to_offers_Text, value: isSwitchedOpenToOffer, onChanged: toggleSwitchOpenToOffer),

        ToggleItem(label: AppStrings.applicable_for_buyer_discounts_Text, value: isSwitchedApplicableBuyerDiscounts, onChanged: toggleSwitchApplicableBuyerDiscounts),

      ]
    ); 
  } 
}
