import 'package:flutter/material.dart';    
import 'package:cherry_mvp/core/config/config.dart'; 


class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});


  @override 
  Widget build(BuildContext context) {     

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [   
        Padding(
          padding: EdgeInsets.only(top: 15),
          child: InkWell(
            onTap: () {},
            child: Text(
              AppStrings.deleteAccountText ?? '',
              style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500,),
            ),
          ),
        ),


        Text(
          AppStrings.appName,
          style: TextStyle(fontSize: 17, color: AppColors.black, fontWeight: FontWeight.w800,),
        ), 
 

        Padding(
          padding: EdgeInsets.only(bottom: 5),
          child:Text(
            AppStrings.appVersion ?? '',
            style: TextStyle(fontSize: 13, color: AppColors.black, fontWeight: FontWeight.w500,),
          ), 
        ),
  
  
      ]
    ); 
  } 
}
