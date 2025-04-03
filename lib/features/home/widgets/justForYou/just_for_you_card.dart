import 'dart:io';
 
import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';  
import 'package:cherry_mvp/core/models/model.dart';

class JustForYouCard extends StatelessWidget {
  const JustForYouCard({
    super.key,
    required this.product,
    required this.flagSize,
  });
  
  final Product product; 
  final bool flagSize;
 

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
                child: Image.network(
                  width: MediaQuery.of(context).size.width / 2.35, // Set width
                  height: 140, // Set height 
                  product.product_image,
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
                                color: AppColors.greenBgColor, // Set background color
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
                                    product.number.toString(),
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
                              product.charity_image,
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
                                    product.likes.toString() ?? 0.toString(),
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
                    product.name ?? '',
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
                    '£${product.price.toStringAsFixed(2)}',
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
                        'M', 
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
