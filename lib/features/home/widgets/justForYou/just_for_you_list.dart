 
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For Cupertino icons
import 'package:carousel_slider/carousel_slider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/features/home/widgets/justForYou/just_for_you_card.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart'; 

class JustForYouList extends StatefulWidget {
  const JustForYouList({super.key});

  @override
  JustForYouListState createState() => JustForYouListState();
}

class JustForYouListState extends State<JustForYouList> {
  @override
  Widget build(BuildContext context) { 

    return Consumer<HomeViewModel>( 
      builder: (context, viewModel, child) {
      final products = viewModel.fetchProducts();

      return Scaffold( 
        backgroundColor: Colors.white,
        appBar: AppBar(
          // arrow back
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back, 
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
            AppStrings.justForYouText,
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
              Center(child:
              Container(
                width: 600, // Set width
                height: MediaQuery.of(context).size.height * 0.74,
                child: GridView.builder( 
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent( 
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
                      return JustForYouCard(
                          product: products[index], flagSize: true);
                    }),
              ),
              ),
              // End second child of column
            ],
          ),
        )
      );
    }); 
  }
}
