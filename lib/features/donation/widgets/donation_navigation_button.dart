import 'package:flutter/material.dart';    
import 'package:cherry_mvp/core/config/config.dart';  
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart'; 
 

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
        Expanded(
          child: PrimaryAppOutlineButton(
            onPressed: onPressedBackButton, 
            buttonText: AppStrings.back 
          ), 
        ),
        
        // Best practice for spacing; it is not advised to use SizedBox
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0), 
        ), 
        
        // NEXT button 
        Expanded(
          child: PrimaryAppButton(
            onPressed: onPressedNextButton, 
            buttonText: AppStrings.next 
          ), 
        )

      ]
    );
  } 
}
