// liked_items_list.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For Cupertino icons
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/features/home/widgets/justForYou/just_for_you_card.dart';
import 'package:cherry_mvp/data/dummy_product.dart';

class JustForYouList extends StatefulWidget {
  const JustForYouList({super.key});

  @override
  JustForYouListState createState() => JustForYouListState();
}

class JustForYouListState extends State<JustForYouList> {
  @override
  Widget build(BuildContext context) {
    // const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold,);

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
            "Just for you",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.only(
              left: 15.0, right: 15.0, top: 0.0, bottom: 20),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 20,
              ),

              // second child of column
              Container(
                width: 600, // Set width
                height: MediaQuery.of(context).size.height * 0.74,
                child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      // childAspectRatio: 1, // Adjust the size ratio of items
                      // childAspectRatio: 0.9, // Adjust the size ratio of items
                      childAspectRatio: 0.65, // Adjust the size ratio of items
                    ),
                    itemCount: dummyProduct.length, // Number of items
                    itemBuilder: (context, index) {
                      return JustForYouCard(
                          productCarousel: dummyProduct[index], flagSize: true);
                    }),
              ),
              // End second child of column
            ],
          ),
        ));
  }
}
