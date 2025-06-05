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

        DonationButtonTemplate(onPressed: onPressedBackButton, buttonText: AppStrings.backButton, backgroundColor: AppColors.white, foregroundColor: AppColors.primary, BorderSideColor: AppColors.primary),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0), 
        ), 

        DonationButtonTemplate(onPressed: onPressedNextButton, buttonText:  AppStrings.nextButton, backgroundColor: AppColors.primary, foregroundColor: AppColors.white, BorderSideColor: AppColors.primary),

      ]
    );
  } 
}
