import 'dart:io';

import 'package:flutter/material.dart';   

import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/models/model.dart';  
import 'package:cherry_mvp/features/settings/widgets/category_card.dart';



class SingleCategory extends StatelessWidget {
  const SingleCategory({super.key, required this.product,});

  final SectionSettings product;  

  @override
  Widget build(BuildContext context) {   
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [   
        SizedBox( 
          height: 15, 
        ), 

        Container( 
          child: Text( 
            product.header,
            style: TextStyle(fontSize: 17, color: AppColors.black, fontWeight: FontWeight.w800,),
          ),
        ), 
 
        ...product.list_items.map((item) => SingleCategoryCard(product: item)).toList(),
        
      ]
    );  
  }
}
