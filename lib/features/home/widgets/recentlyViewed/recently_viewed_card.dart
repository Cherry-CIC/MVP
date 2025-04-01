import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/core/models/product_carousel.dart';

class RecentlyViewedCard extends StatelessWidget {
  const RecentlyViewedCard({super.key, required this.productCarousel});

  final ProductCarousel productCarousel; 

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white, // Set background color
      elevation: 4, // Adds a shadow effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50), // Set border radius
      ),

      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
        child: Stack(
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                productCarousel.image, // Replace with your image path
                width: MediaQuery.of(context).size.width / 6,
                height: 60, // Adjust height as needed
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
