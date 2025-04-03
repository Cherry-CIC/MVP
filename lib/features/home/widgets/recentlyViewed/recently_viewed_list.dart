import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For Cupertino icons
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/features/home/widgets/recentlyViewed/recently_viewed_list_card.dart';
 
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';  

class RecentlyViewedList extends StatefulWidget {
  const RecentlyViewedList({super.key});

  @override
  RecentlyViewedListState createState() => RecentlyViewedListState();
}

class RecentlyViewedListState extends State<RecentlyViewedList> {
  @override
  Widget build(BuildContext context) {
    // const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold,);

    return Consumer<HomeViewModel>( 
      builder: (context, viewModel, child) {
      final products = viewModel.fetchProducts();

      return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // arrow back
        leading: IconButton(
          icon: Icon(
            // Icons.arrow_back,
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

            // first row
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
                          // color:AppColors.primary,
                        ),
                      ),
                    ),
                  ]),
                  Column(children: [
                    Container(
                      // width:MediaQuery.of(context).size.width * 0.6,
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

            // second child of column
            Center(child:
            Container(
              width: 600, // Set width
              height: MediaQuery.of(context).size.height * 0.66,
              child: GridView.builder(
                // gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  // crossAxisCount: 2, // Number of columns
                  maxCrossAxisExtent: 150,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,  
                  childAspectRatio: 
                   
                   (MediaQuery.of(context).size.width > 504 && MediaQuery.of(context).size.width <= 567)
                   ? 0.49 
                   :(MediaQuery.of(context).size.width >=346 && MediaQuery.of(context).size.width <= 430) 
                   ? 0.47
                   : 0.65,
                ),
                itemCount: products.length, // Number of items
                itemBuilder: (context, index) {
                  return RecentlyViewedListCard(product: products[index], flagSize: true);
                }
              ),
            ),
            ), 
          ],
        ),
      )
    );
    }); 
  }
}
