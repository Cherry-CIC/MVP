// liked_items_list.dart
import 'dart:io'; 

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For Cupertino icons
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/features/home/widgets/likedItems/liked_items_list_card.dart';
import 'package:cherry_mvp/data/dummy_product.dart';

class LikedItemsList extends StatefulWidget {
  const LikedItemsList({super.key});

  @override
  LikedItemsListState createState() => LikedItemsListState();
}

class LikedItemsListState extends State<LikedItemsList> {  

  @override 
  Widget build(BuildContext context) {  
    return Scaffold( 
      backgroundColor: Colors.white, 
      appBar: AppBar( 


        // arrow back
        leading: IconButton(
          icon: Icon(
            // Icons.arrow_back,
            CupertinoIcons.back,
            color: Colors.red,  // Customize the color of the arrow
            size: 20,             // Customize the size of the arrow
          ),
          onPressed: () {
            // Pop the current screen when the back button is pressed
            Navigator.pop(context);
          },
        ), 
        
        // text header
        title: Text(
          AppStrings.likedItemsText,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold ),
        ), 
        centerTitle: true, 

        // action button favorite 
        actions: [  
          Card(
            color: AppColors.lightGreyTextColor, // background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40), // Set the border radius here
            ),
            child:Padding(
              padding: const EdgeInsets.only(left:0.5,right: .05,), 
 
              child:Stack(
                alignment: Alignment.center,
                children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: AppColors.primary,  
                   size: 20,  
                  ),
                  onPressed: (){}, 
                ),

                // Number inside the favorite icon
                Positioned(
                  top: 12, // Adjust the position of the number
                  right: 17,
                  child: Text(
                    '7', // Number inside the icon
                    style: TextStyle(
                      color: AppColors.white, 
                      fontSize: 10,
                    ),
                  ),
                ),
                ]
              ), 
            ),
          ), 
        ], 

      ), 
      body: DecoratedBox( 
        // BoxDecoration takes the image
        decoration: BoxDecoration( 
          // Image set to background of the body
          /* image: DecorationImage( 
            image: AssetImage(AppImages.welcomeBg), 
            fit: BoxFit.fill
          ), */
        ),

        child: ListView.builder(
          itemCount: dummyProduct.length,  // Set the total number of items
          itemBuilder: (context, index) {
            return LikedItemListCard(productCarousel: dummyProduct[index]);
          },
        ), 

            
      ),
    ); 
  } 
}
