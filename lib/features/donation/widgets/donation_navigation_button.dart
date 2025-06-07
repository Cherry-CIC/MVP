import 'package:flutter/material.dart';    
import 'package:cherry_mvp/core/config/config.dart';  
import 'package:cherry_mvp/features/donation/widgets/donation_button_template.dart'; 
 

class DonationNavigationButton extends StatelessWidget { 

  const DonationNavigationButton({
    super.key,
    required this.onPressedBackButton,
    required this.onPressedNextButton, 
  });   


  final VoidCallback onPressedBackButton; 
  final VoidCallback onPressedNextButton;  
  
     
 
  @override 
  Widget build(BuildContext context) {    

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [  
        
        // BACK button
        DonationButtonTemplate(onPressed: onPressedBackButton, buttonText: AppStrings.back, backgroundColor: AppColors.white, foregroundColor: AppColors.primary, borderSideColor: AppColors.primary),
        
        // Best practice for spacing; it is not advised to use SizedBox
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0), 
        ), 
        
        // NEXT button
        DonationButtonTemplate(onPressed: onPressedNextButton, buttonText:  AppStrings.next, backgroundColor: AppColors.primary, foregroundColor: AppColors.white, borderSideColor: AppColors.primary),

      ]
    );
  } 
}
