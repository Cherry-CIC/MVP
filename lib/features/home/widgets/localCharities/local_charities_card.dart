import 'dart:io';

import 'package:flutter/material.dart'; 
 
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart'; 
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart'; 
import 'package:cherry_mvp/core/models/model.dart'; 
   
class LocalCharitiesCard extends StatelessWidget {
  const LocalCharitiesCard({super.key, required this.charityLogo});

  final CharityLogo charityLogo;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,  
      elevation: 4,  
      shape: RoundedRectangleBorder( 
        borderRadius: BorderRadius.circular(30),  
      ),

      child: Stack(
        children: [ 
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              charityLogo.charity_image, // Replace with your image path 
              width: MediaQuery.of(context).size.width*0.42, 

              fit: BoxFit.fill,
            ),
          ),  
        ],
      ),
    );
  }
}
