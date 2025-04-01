import 'dart:io';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/features/home/widgets/recentlyViewed/recently_viewed_card.dart';
import 'package:cherry_mvp/features/home/widgets/recentlyViewed/recently_viewed_list_bottom.dart';
import 'package:cherry_mvp/data/dummy_product.dart';

class RecentlyViewed extends StatefulWidget {
  const RecentlyViewed({super.key}); 

  @override
  RecentlyViewedState createState() => RecentlyViewedState();
}

class RecentlyViewedState extends State<RecentlyViewed> { 


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 15.0, right: 15.0, 
          top: 0.0, bottom: 20),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 20,
          ),

          // first child of column
          Padding(
            padding: const EdgeInsets.only(
              top: 0.0,
              left: 5.0,
              right: 5.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // first child of row
                Padding(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    left: 0.0,
                  ),
                  child: Text(
                    "Recently Viewed Items",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black),
                  ),
                ),
                // End first child of row

                // second child of row
                Padding(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    left: 0.0,
                  ), 

                  child: TextButton(
                    onPressed: () {
                      Navigator.push( context,
                        MaterialPageRoute(builder: (context) => RecentlyViewedListBottom()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary, // Sets the text color
                    ),
                    child: Text("See All"),
                  ),
                ),
                // End second child of row
              ],
            ),
          ),
          // End first child of column

          // second child of column
          Padding(
            padding: const EdgeInsets.only(
              top: 0.0,
              left: 0.0,
            ),

            child: Center(
              child: CarouselSlider(
                options: CarouselOptions( 
                  height: 60, // Adjust height
                  autoPlay: false, // Enables auto-scrolling
                  enlargeCenterPage: false, // Zooms the center item 
                  viewportFraction: 0.2, // Controls visible portion of adjacent images
                  initialPage: 0, // Ensure the first image is in view
                  enableInfiniteScroll: true, // Prevent looping
                ),
                items: dummyProduct.map((productItem) {
                  return Builder(
                    builder: (BuildContext context) { 

                      return RecentlyViewedCard(productCarousel: productItem); 
                    },
                  );
                }).toList(),
              ),
            ), 
          ),
          // End second child of column 
        ],
      ),
    );
  }
}
