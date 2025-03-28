import 'dart:io';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/features/home/widgets/liked_item_card.dart';
import 'package:cherry_mvp/data/dummy_product_carousel.dart';

class LikedItems extends StatefulWidget {
  const LikedItems({super.key});

  @override
  LikedItemsState createState() => LikedItemsState();
}

class LikedItemsState extends State<LikedItems> {
  final List<String> images = [
    AppImages.clothing1,
    AppImages.clothing2,
    AppImages.clothing3,
    AppImages.clothing3,
    AppImages.clothing3,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 15.0, right: 15.0, top: 0.0, bottom: 20),
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
                    AppStrings.likedItemsText,
                    style: TextStyle(
                        fontSize: 20,
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
                  child: IconButton(
                    icon: ClipRRect(
                      // borderRadius: BorderRadius.circular(10.0),
                      child: Image.asset(
                        width: 30, // Set width
                        height: 30, // Set height
                        AppImages.icButton,
                        fit: BoxFit.fill,
                      ),
                    ),
                    onPressed: () {
                      // print("Icon Button Pressed");
                    },
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
                  height: 150, // Adjust height
                  autoPlay: true, // Enables auto-scrolling
                  enlargeCenterPage: false, // Zooms the center item
                  // aspectRatio: 16 / 9,
                  // viewportFraction: 0.3, // Controls visible portion of adjacent images
                  viewportFraction: 0.33, // Controls visible portion of adjacent images
                  initialPage: 0, // Ensure the first image is in view
                  enableInfiniteScroll: true, // Prevent looping
                ),
                items: dummyProductCarousel.map((productItem) {
                  return Builder(
                    builder: (BuildContext context) { 

                      return LikedItemCard(productCarousel: productItem); 
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
