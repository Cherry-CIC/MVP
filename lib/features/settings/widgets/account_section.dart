import 'package:flutter/material.dart';   
import 'package:cherry_mvp/core/config/config.dart'; 


class AccountSection extends StatelessWidget {
  const AccountSection({super.key});  


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
            AppStrings.account_Text,
            style: TextStyle(fontSize: 17, color: AppColors.black, fontWeight: FontWeight.w800,),
          ),
        ),

        // Language
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
                          AppStrings.language_Text,
                          style: TextStyle(color: AppColors.greyTextColor, fontWeight: FontWeight.w600,),
                        ),
                      ),
                    ]
                  ),
                ]
              ),

              Column(
                children: [  
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(0.0),
                        child: Text(
                          AppStrings.english_Text,
                          style: TextStyle(color: AppColors.greyTextColor, fontWeight: FontWeight.w600,),
                        ),
                      ),

                      Icon(
                        Icons.chevron_right,
                        color: AppColors.greyTextColor, 
                        size: 26,
                      ), 
                    ]
                  )
                ]
              ),
            ]
          ),
        ), 

        Divider(), 



        SizedBox( 
          height: 10, 
        ), 


        // Security
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
                          AppStrings.security_Text,
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


        // About us
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
                          AppStrings.about_us_Text,
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


        // Legal information
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
                          AppStrings.legal_information_Text,
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


        // Cookie settings
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
                          AppStrings.cookie_settings_Text,
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


        // Log out
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
                          AppStrings.log_out_Text,
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
