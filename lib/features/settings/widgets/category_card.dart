import 'package:flutter/material.dart';   

import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/models/model.dart';  

class SingleCategoryCard extends StatelessWidget {
  const SingleCategoryCard({super.key, required this.product,});

  final SectionSettingsItem product;  

  @override
  Widget build(BuildContext context) {   
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [ 

        SizedBox( 
          height: 20, 
        ), 
 
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
                          product.subheader,
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
                          product.subheaderArrow,
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
