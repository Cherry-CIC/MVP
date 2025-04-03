import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/core/models/model.dart';

class LikedItemListCard extends StatelessWidget {
  const LikedItemListCard({super.key, required this.productCarousel});

  final ProductCarousel productCarousel;

  static const currency = "\$";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 0.0, // right:1.0, left:1.0
      ),
      child: Center(
        child: Container(
          width: double.infinity, 
 
          child: Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[ 
              Column(
                children: [
                  Card(
                    color: AppColors.primary, // Set background color
                    elevation: 4, // Adds a shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30), // Set border radius
                    ),

                    child: Stack(
                      children: [
                        // Background Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            width: MediaQuery.of(context).size.width / 3, // Set width
                            height: 100, // Set height 
                            productCarousel.image,
                            fit: BoxFit.fill,
                          ),
                        ),

                        Column(
                          children: <Widget>[ 
                            Container(
                              width: MediaQuery.of(context).size.width / 3,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 28, 
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Card(
                                      color: Colors.greenAccent[ 400], // Set background color
                                      elevation: 4, // Adds a shadow effect
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7.0), // Set border radius
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 7.0, left: 7.0),
                                        child: Text(
                                          productCarousel.numberIndexes.toString(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Container(
                              width: MediaQuery.of(context).size.width / 3,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  // bottom:75,
                                  // left: 100,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.network(
                                        width: 45, // Set width
                                        height: 50, // Set height
                                        productCarousel.charityLogo,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
 
              Column(
                children: [ 
                  Container(
                    width: MediaQuery.of(context).size.width * 0.63,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            productCarousel.description ?? '',
                            style: TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
 
                  Container(
                    width: MediaQuery.of(context).size.width * 0.63,
                    padding: EdgeInsets.only(
                      bottom: 0.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            productCarousel.size ?? '',
                            style: TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
 
                  Container(
                    width: MediaQuery.of(context).size.width * 0.63,
                    padding: EdgeInsets.only(
                      bottom: 0.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(children: [
                          Text( 
                            currency + (productCarousel.price ?? 0).toStringAsFixed(2),
                            style: TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ]),
                        Column(children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.43,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // delete icon
                                Padding(
                                  padding: EdgeInsets.only(
                                  left: 0.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                  color: AppColors .lightGreyTextColor, // Background color
                                  borderRadius: BorderRadius.circular(50), // Optional: to make the background rounded
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                            ),

                            // add to cart icon
                            Padding(
                              padding: EdgeInsets.only(
                                left: 0.0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreyTextColor, // Background color
                                  borderRadius: BorderRadius.circular(50), // Optional: to make the background rounded
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.add_shopping_cart,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                            ),

                            // number icon with the favorite icon
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 0.0,
                                horizontal: 0.0,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 2.0,
                                  horizontal: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreyTextColor, // Background color
                                  borderRadius: BorderRadius.circular(50), // Optional: to make the background rounded
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // number icon
                                    Card(
                                      color: AppColors.primary, // background color
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50), // Set the border radius here
                                      ),

                                      child: InkWell(
                                        // Adds tap effect
                                        onTap: () {},
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 3.0,
                                            horizontal: 6.0
                                          ),
                                          child: Text(
                                            // "10",
                                            productCarousel.numberLikes.toString() ?? 0.toString(),
                                            style: TextStyle(
                                              color: AppColors.white),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // favorite icon
                                      Positioned(
                                        top: -1, // Adjust the position of the number
                                        right: 0,
                                        child: Icon(
                                          Icons.favorite,
                                          color: Colors.red, size: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ), 
                            ]),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
