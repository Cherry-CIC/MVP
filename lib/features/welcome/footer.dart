import 'package:flutter/material.dart';    
import 'package:cherry_mvp/core/config/config.dart'; 


class Footer extends StatelessWidget { 
  const Footer({super.key});  


  @override 
  Widget build(BuildContext context) {     

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [   
      
        Padding(
          padding: EdgeInsets.only(top: 15),
          child: InkWell(
            onTap: () {},
            child: Container( 
              child: Text(
                AppStrings.delete_account_Text,
                style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500,),
              ),
            ),
          ),
        ),

        Container( 
          child: Text(
            AppStrings.appName,
            style: TextStyle(fontSize: 17, color: AppColors.black, fontWeight: FontWeight.w800,),
          ),
        ),

        Container( 
          padding: EdgeInsets.only(bottom: 5),
          child: Text(
            "Version 1.0 April, 2025",
            style: TextStyle(fontSize: 13, color: AppColors.black, fontWeight: FontWeight.w500,),
          ),
        ), 
  
      ]
    ); 
  } 
}
