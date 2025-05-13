import 'package:flutter/material.dart';   
import 'package:cherry_mvp/core/config/config.dart';  
 

class ToggleSection extends StatefulWidget {
  const ToggleSection({super.key});  



  @override
  ToggleSectionState createState() => ToggleSectionState();
}

 

class ToggleSectionState extends State<ToggleSection> { 
  
  bool isSwitchedDark = false;
  bool isSwitchedHide = false;

  void toggleSwitchDark(bool value) {
    setState(() {
      isSwitchedDark = value; 
    });
  } 

  void toggleSwitchHide(bool value) {
    setState(() {
      isSwitchedHide = value; 
    });
  } 

  @override 
  Widget build(BuildContext context) {     

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [   
        SizedBox( 
          height: 15, 
        ),  
        
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isSwitchedDark,
            onChanged: toggleSwitchDark, 
            activeColor: AppColors.primary, 
            // activeTrackColor: AppColors.redBgColor,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.greyTextColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, 
          ), 
        ),

        Text(
          AppStrings.dark_mode_Text,
          style: TextStyle(fontSize: 13, color: AppColors.greyTextColor, fontWeight: FontWeight.w600,),
        ),

        
        
        SizedBox( 
          height: 5, 
        ),
        
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isSwitchedHide,
            onChanged: toggleSwitchHide, 
            activeColor: AppColors.primary, 
            // activeTrackColor: AppColors.redBgColor,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.greyTextColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, 
          ), 
        ),

        Text(
          AppStrings.list_listings_Text,
          style: TextStyle(fontSize: 13, color: AppColors.greyTextColor, fontWeight: FontWeight.w600,),
        ),


  
      ]
    ); 
  } 
}
