import 'package:flutter/material.dart';   
import 'package:flutter/cupertino.dart';
import 'package:cherry_mvp/core/config/config.dart';  
 

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

        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical:10.0, horizontal:15.0),
          margin: EdgeInsets.only(bottom:20.0),
          decoration: BoxDecoration(
            color: AppColors.lightGreyFill, 
            borderRadius: BorderRadius.circular(50.0),
          ), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.open_to_other_charities_Text,
                style: TextStyle(fontSize: 15, color: AppColors.greyTextColor, fontWeight: FontWeight.w300,),
              ),

              CupertinoSwitch( 
                value: isSwitchedOpenToOtherCharity,
                onChanged: toggleSwitchOpenToOtherCharity, 
                inactiveTrackColor: AppColors.greyTextColor, 
                activeColor: AppColors.primary, 
              )
            ]
          )
        ), 


        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical:10.0, horizontal:15.0),
          margin: EdgeInsets.only(bottom:20.0),
          decoration: BoxDecoration(
            color: AppColors.lightGreyFill, 
            borderRadius: BorderRadius.circular(50.0),
          ), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.open_to_offers_Text,
                style: TextStyle(fontSize: 15, color: AppColors.greyTextColor, fontWeight: FontWeight.w300,),
              ),

              CupertinoSwitch( 
                value: isSwitchedOpenToOffer,
                onChanged: toggleSwitchOpenToOffer, 
                inactiveTrackColor: AppColors.greyTextColor, 
                activeColor: AppColors.primary, 
              )
            ]
          )
        ), 


        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical:10.0, horizontal:15.0),
          margin: EdgeInsets.only(bottom:20.0),
          decoration: BoxDecoration(
            color: AppColors.lightGreyFill, 
            borderRadius: BorderRadius.circular(50.0),
          ), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.applicable_for_buyer_discounts_Text,
                style: TextStyle(fontSize: 13, color: AppColors.greyTextColor, fontWeight: FontWeight.w300,),
              ),

              CupertinoSwitch( 
                value: isSwitchedApplicableBuyerDiscounts,
                onChanged: toggleSwitchApplicableBuyerDiscounts, 
                inactiveTrackColor: AppColors.greyTextColor, 
                activeColor: AppColors.primary, 
              )
            ]
          )
        ), 

      ]
    ); 
  } 
}
