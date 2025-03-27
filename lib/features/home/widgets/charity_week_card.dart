import 'dart:io';

import 'package:flutter/material.dart'; 

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';

class CharityWeekCard extends StatefulWidget {
  const CharityWeekCard({super.key});

  @override  
  CharityWeekCardState createState() => CharityWeekCardState();
}

class CharityWeekCardState extends State<CharityWeekCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15.1, top: 0.0, bottom: 10.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Set border radius
        ),
        child: Stack(
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                AppImages.redBackground, // Replace with your image path
                width: double.infinity,
                height: 170, // Adjust height as needed
                fit: BoxFit.cover,
              ),
            ),

            Column(
              children: <Widget>[
                SizedBox(
                  height: 10,
                ),

                //  text Charity of
                Padding(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    left: 15.0,
                  ),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 30,
                          child: Text(
                            AppStrings.charityOfText,
                            style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //  text  the week
                Padding(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    left: 15.0,
                    bottom: 0.0,
                  ),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 25,
                          child: Text(
                            AppStrings.weekText,
                            style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    top: 30.0,
                    left: 15.0,
                    bottom: 0.0,
                  ),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 20,
                          child: Text(
                            AppStrings.browseItemsText,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    left: 15.0,
                    bottom: 0.0,
                  ),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 20,
                          child: Text(
                            AppStrings.learMoreText,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    left: 15.0,
                    bottom: 0.0,
                  ),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 20,
                          child: Text(
                            AppStrings.workHereText,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
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
