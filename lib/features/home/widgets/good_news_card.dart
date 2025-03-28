import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';

class GoodNewsCard extends StatefulWidget {
  const GoodNewsCard({super.key});

  @override
  GoodNewsCardState createState() => GoodNewsCardState();
}

class GoodNewsCardState extends State<GoodNewsCard> {
  

  @override
  Widget build(BuildContext context) {
    // Get screen width and height
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding:
          const EdgeInsets.only(left: 15.0, right: 15.0, top: 0.0, bottom: 10),
      child: Card(
        color: AppColors.primary, // Set background color
        elevation: 4, // Adds a shadow effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Set border radius
        ),
        child: Stack(
          children: [
            // Background Image
            /* ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                AppImages.redBackground, // Replace with your image path
                width: double.infinity,
                height: 130, // Adjust height as needed
                fit: BoxFit.cover,
              ),
            ), */

            Column(
              children: <Widget>[
                SizedBox(
                  height: 10,
                ),

                //
                Padding(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    left: 5.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 0.0,
                              left: 0.0,
                            ),
                            child: Text(
                              AppStrings.amazingCharityText,
                              style: TextStyle( // screenWidth
                                  fontSize: 16,
                                  // fontSize: screenWidth/15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white),
                            ),
                          ), 

                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              left: 0.0,
                            ),
                            child: Text(
                              AppStrings.amazingWorkText,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              left: 0.0,
                            ),
                            child: Text(
                              AppStrings.seeGoodNewsText,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.white),
                            ),
                          ), 

                          //
                        ],
                      ),

                      //
                      Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 60.0,
                                  // left: 15.0,
                                  bottom: 0.0,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Image.asset(
                                    width: 45, // Set width  
                                    height: 35, // Set height 
                                    AppImages.logoSaveChildren,
                                    // 'assets/images/g.png',
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),  

                              Padding(
                                padding: const EdgeInsets.only(
                                  // top: 30.0,
                                  // left: 15.0,
                                  bottom: 0.0,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(40.0),
                                  child: Image.asset(
                                    width: 70, // Set width
                                    height: 110, // Set height
                                    AppImages.childSaveChildren,
                                    // 'assets/images/g.png',
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              //
                            ],
                          ),
                        ],
                      ),
                      //
                    ],
                  ),
                ),

                SizedBox(
                  height: 10,
                ),

                //
              ],
            ),
          ],
        ),
      ),
    );
  }
}
