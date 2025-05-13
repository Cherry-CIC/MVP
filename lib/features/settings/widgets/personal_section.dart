import 'package:flutter/material.dart';   
import 'package:cherry_mvp/core/config/config.dart'; 


class PersonalSection extends StatelessWidget {
  const PersonalSection({super.key});  


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
            AppStrings.personal_Text,
            style: TextStyle(fontSize: 17, color: AppColors.black, fontWeight: FontWeight.w800,),
          ),
        ),

        // Profile
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
                          AppStrings.profile_Text,
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


        // Shipping Address
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
                          AppStrings.shipping_address_Text,
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


        // Payment methods
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
                          AppStrings.payment_methods_Text,
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


        // Postage
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
                          AppStrings.postage_Text,
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
