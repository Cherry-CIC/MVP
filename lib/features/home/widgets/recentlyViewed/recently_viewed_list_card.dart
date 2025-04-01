import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/core/models/product_carousel.dart';

class RecentlyViewedListCard extends StatelessWidget {
  const RecentlyViewedListCard({
    super.key,
    required this.productCarousel,
    required this.flagSize,
  });

  final ProductCarousel productCarousel;
  final bool flagSize;

  static const currency = "\$";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      height: 50,
      child: Stack(children: [
        Column(children: [
          Stack(
            children: [
              // Background Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                /* child: Image.asset(
                  AppImages.redBackground, // Replace with your image path
                  width: MediaQuery.of(context).size.width / 2.35,
                  height: 140, // Adjust height as needed

                  fit: BoxFit.cover,
                ), */
                child: Image.network(
                  width: MediaQuery.of(context).size.width / 2.35, // Set width
                  height: 140, // Set height 
                  productCarousel.image,
                  fit: BoxFit.fill,
                ),
              ),

              Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 0.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              // right:2,
                              ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Card(
                                color: Colors
                                    .greenAccent[400], // Set background color
                                elevation: 4, // Adds a shadow effect
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      7.0), // Set border radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 7.0, left: 7.0),
                                  child: Text(
                                    // 20.toString(),
                                    productCarousel.numberIndexes.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 58.0,
                      left: 0.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 0.0,
                            bottom: 0.0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            /* child: Image.asset(
                              width: 45, // Set width
                              height: 50, // Set height
                              AppImages.logoSaveChildren,
                              fit: BoxFit.fill,
                            ), */

                            child: Image.network(
                              width: 45, // Set width
                              height: 50, // Set height
                              productCarousel.charityLogo,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 26.0,
                            bottom: 0.0,
                          ),
                          child: Card(
                            color: AppColors.white, // Set background color
                            elevation: 4, // Adds a shadow effect
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  7.0), // Set border radius
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
                                    )),

                                // number of likes
                                Padding(
                                  padding: const EdgeInsets.only(right: 0.0),
                                  child: Text(
                                    // 12.toString(),
                                    productCarousel.numberLikes.toString() ?? 0.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.63,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    // 'i like that thhat way oh',
                    productCarousel.description ?? '',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.63,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(children: [
                  Text(
                    // "\$4.00",
                    currency + (productCarousel.price ?? 0).toStringAsFixed(2),
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ]),

                
                  
                Column(children: [ 
                  Card(
                    color: Colors.lightBlue, // Set background color
                    elevation: 4, // Adds a shadow effect
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(2), // Set border radius
                    ),
                    child: (flagSize) ? Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 0.5, horizontal: 10.0),
                      child: Text(
                        // 'M',
                        productCarousel.size ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600),
                      ),
                    ) : null
                  ) 
                ]),
              ],
            ),
          ),
        ]),
      ]),
    );
  }
}
