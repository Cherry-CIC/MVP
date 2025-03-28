import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/core/models/product_carousel.dart';
 
/* class LikedItemCard extends StatefulWidget {
  const LikedItemCard({super.key, this.productCarousel});

  const ProductCarousel productCarousel;
  // image, charityLogo, numberLikes 
 
  @override
  LikedItemCardState createState() => LikedItemCardState();
} */

class LikedItemCard extends StatelessWidget {
  const LikedItemCard({super.key, required this.productCarousel});

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
              productCarousel.image, // Replace with your image path
              // width: 150,
              // width: MediaQuery.of(context).size.width/2.5,
              width: MediaQuery.of(context).size.width/2.3,
              height: 200, // Adjust height as needed
              fit: BoxFit.cover ,
            ),
          ),

          Column(
            children: <Widget>[
              SizedBox(
                height: 90, 
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 0.0,
                  left: 0.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 0.0,
                        // left: 15.0,
                        bottom: 0.0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.asset(
                          width: 45, // Set width
                          height: 50, // Set height
                          productCarousel.charityLogo, // image
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    //

                    // 
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 24, // i was forced to comment this because there was an overflow
                        // left: 50.0, 
                        bottom: 0.0,
                      ),
                      child: Card( 
                        //
                        color: AppColors.white, // Set background color
                        elevation: 4, // Adds a shadow effect
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(7.0), // Set border radius
                        ),
                        child: Row(
                          children: [
                            // icon favorite
                            Padding(
                              padding: const EdgeInsets.only(right: 1.0),
                              child: Icon(
                                Icons.favorite,
                                color: AppColors.primary,
                                size: 15, // Set icon size
                              )
                            ),

                            // number of likes
                            Padding(
                              padding: const EdgeInsets.only(right: 0.0),
                              child: Text(
                                productCarousel.numberLikes.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        //
                      ),
                    ), 
                    //
                  ],
                ),
              ),

            ],
          ),
          //
        ],
      ),
    );
  }
}
