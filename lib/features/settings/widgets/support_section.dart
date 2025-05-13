import 'package:flutter/material.dart';   
import 'package:cherry_mvp/core/config/config.dart'; 


class SupportSection extends StatelessWidget {
  const SupportSection({super.key});  


  @override 
  Widget build(BuildContext context) {     

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [   
        SizedBox( 
          height: 15, 
        ), 

        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Text(
            AppStrings.support_Text,
            style: TextStyle(fontSize: 17, color: AppColors.black, fontWeight: FontWeight.w800,),
          ),
        ),

        // Chat with us
        InkWell(
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Row(
                    children: [ 

                      Padding(
                        padding: EdgeInsets.all(0.0),
                        child: Text(
                          AppStrings.chat_with_us_Text,
                          style: TextStyle(color: AppColors.greyTextColor, fontWeight: FontWeight.w600,),
                        ),
                      ),
                    ]
                  ),
                ]
              ),

              Column(
                children: [
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.greyTextColor, 
                    size: 26,
                  ),
                ]
              ),
            ]
          ),
        ), 

        Divider(),


        SizedBox( 
          height: 10, 
        ), 


        // FAQ'S
        InkWell(
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Row(
                    children: [ 

                      Padding(
                        padding: EdgeInsets.all(0.0),
                        child: Text(
                          AppStrings.FAQ_Text,
                          style: TextStyle(color: AppColors.greyTextColor, fontWeight: FontWeight.w600,),
                        ),
                      ),
                    ]
                  ),
                ]
              ),

              Column(
                children: [
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.greyTextColor, 
                    size: 26,
                  ),
                ]
              ),
            ]
          ),
        ),  

        Divider(), 
      ]
    ); 
  } 
}
