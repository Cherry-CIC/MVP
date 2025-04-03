import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For Cupertino icons
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/features/home/widgets/recentlyViewed/recently_viewed_list_card.dart';
import 'package:cherry_mvp/data/dummy_product.dart';

class RecentlyViewedList extends StatefulWidget {
  const RecentlyViewedList({super.key});

  @override
  RecentlyViewedListState createState() => RecentlyViewedListState();
}

class RecentlyViewedListState extends State<RecentlyViewedList> {
  @override
  Widget build(BuildContext context) { 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // arrow back
        leading: IconButton(
          icon: Icon( 
            CupertinoIcons.back,
            color: Colors.red, // Customize the color of the arrow
            size: 20, // Customize the size of the arrow
          ),
          onPressed: () {
            // Pop the current screen when the back button is pressed
            Navigator.pop(context);
          },
        ),

        // text header
        title: Text(
          AppStrings.recentlyViewedText,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
          centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only( left: 15.0, right: 15.0, top: 0.0, bottom: 20),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
 
            Container(
              width: MediaQuery.of(context).size.height * 0.74,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(children: [
                    Padding(
                      padding: EdgeInsets.only(left: 0.0),
                      child: Text(
                        AppStrings.todayText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold, 
                        ),
                      ),
                    ),
                  ]),
                  Column(children: [
                    Container( 
                      padding: EdgeInsets.only(
                        right: 0.0,
                        left: 20.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50), // Set border radius
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: 0.0,
                                left: 20.0, 
                              ),
                              child: Row(children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: 0.0,
                                    left: 50.0,
                                  ),
                                  child: Text(
                                    AppStrings.aprilDateText,
                                    style: TextStyle(
                                      color: AppColors.primary
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 30,
                                  height: 30,
                                  child: Stack(children: [
                                    Card(
                                      color: AppColors.primary, // Set background color
                                      elevation: 4, // Adds a shadow effect
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50), // Set border radius
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10.0,
                                          horizontal: 10.0
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.check), // Tick icon
                                          onPressed: () {},
                                          iconSize:50.0, // Size of the icon
                                          color: AppColors.white, // Color of the icon
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -5.0,
                                      top: -5.0,
                                      child: IconButton(
                                        icon: Icon(Icons.check), // Tick icon
                                        onPressed: () {},
                                        iconSize:15.0, // Size of the icon
                                        color: AppColors.white, // Color of the icon
                                      ),
                                    ),
                                  ]),
                                ),
                              ]),
                            ),
                          ),

                          IconButton(
                            icon: Icon(Icons.keyboard_arrow_down), // Tick icon
                            onPressed: () {},
                            iconSize: 30.0, // Size of the icon
                            color: AppColors.primary, // Color of the icon
                          ),
                        ]
                      ),
                    ),
                  ]),
                ]
              ),
            ),
 
            Container(
              width: 600, // Set width
              height: MediaQuery.of(context).size.height * 0.66,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1, 
                  childAspectRatio: 0.65, // Adjust the size ratio of items
                ),
                itemCount: dummyProduct.length, // Number of items
                itemBuilder: (context, index) {
                  return RecentlyViewedListCard(productCarousel: dummyProduct[index], flagSize: true);
                }
              ),
            ), 
          ],
        ),
      )
    );
  }
}
