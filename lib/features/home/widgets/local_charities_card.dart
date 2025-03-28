import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart'; 
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/core/models/product_carousel.dart';
 
class LocalCharitiesCard extends StatelessWidget {
  const LocalCharitiesCard({super.key, required this.productCarousel});

  final ProductCarousel productCarousel;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.transparent, // Set background color
      elevation: 4, // Adds a shadow effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30), // Set border radius
      ),

      child: Stack(
        children: [
          // Background Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              productCarousel.charityLogo, // Replace with your image path
              // width: 130,
              width: MediaQuery.of(context).size.width/2.35,
              height: 600, // Adjust height as needed

              fit: BoxFit.cover,
            ),
          ), 
          //
        ],
      ),
    );
  }
}
