import 'package:flutter/material.dart';   
import 'package:flutter/cupertino.dart';
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

        Padding(
          padding: EdgeInsets.only(top:15.0),

          child: CupertinoSwitch( 
            value: isSwitchedDark,
            activeTrackColor: CupertinoColors.activeBlue,
            onChanged: toggleSwitchDark,
          ),
        ), 
         

        Text(
          AppStrings.dark_mode_Text,
          style: TextStyle(fontSize: 13, color: AppColors.greyTextColor, fontWeight: FontWeight.w600,),
        ),

         

        Padding(
          padding: EdgeInsets.only(top:5.0),

          child: CupertinoSwitch( 
            value: isSwitchedHide,
            activeTrackColor: CupertinoColors.activeBlue,
            onChanged: toggleSwitchHide,
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
