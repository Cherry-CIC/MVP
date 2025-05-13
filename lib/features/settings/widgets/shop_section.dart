import 'package:flutter/material.dart';    
import 'package:cherry_mvp/core/config/config.dart'; 


class ShopSection extends StatelessWidget {
  const ShopSection({super.key});  


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
            AppStrings.shop_Text,
            style: TextStyle(fontSize: 17, color: AppColors.black, fontWeight: FontWeight.w800,),
          ),
        ),

        // Country
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
                          AppStrings.country_Text,
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
                          AppStrings.united_kingdom_Text,
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


        // Currency
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
                          AppStrings.currency_Text,
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
                          AppStrings.pound_Text,
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


        // Sizes
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
                          AppStrings.sizes_Text,
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
                          AppStrings.UK_Text,
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
      ]
    ); 
  } 
}
