import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';

class LikedItemCard extends StatefulWidget {
  const LikedItemCard({super.key});

  @override
  LikedItemCardState createState() => LikedItemCardState();
}

class LikedItemCardState extends State<LikedItemCard> {
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
              AppImages.redBackground, // Replace with your image path
              width: 130, 
              height: 130, // Adjust height as needed
              fit: BoxFit.cover,
            ),
          ),

          Column(
            children: <Widget>[
              SizedBox(
                height: 75,
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
                          AppImages.logoSaveChildren,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    //

                    //
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 30.0,
                        left: 50.0,
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
                                )),

                            // number of likes
                            Padding(
                              padding: const EdgeInsets.only(right: 0.0),
                              child: Text(
                                12.toString(),
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
