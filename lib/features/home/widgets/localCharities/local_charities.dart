import 'dart:io';

import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/features/home/widgets/localCharities/local_charities_card.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart'; 

class LocalCharities extends StatefulWidget {
  const LocalCharities({super.key});

  @override
  LocalCharitiesState createState() => LocalCharitiesState();
}

class LocalCharitiesState extends State<LocalCharities> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>( 
      builder: (context, viewModel, child) {
      final charityLogos = viewModel.fetchCharityLogos();

      return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 0.0, ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
 
          Padding(
            padding: const EdgeInsets.only(
              top: 0.0,
              left: 5.0,
              right: 5.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [ 
                Padding(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    left: 0.0,
                  ),
                  child: Text( 
                    AppStrings.localCharityText,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black),
                  ),
                ), 

                Padding(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    left: 0.0,
                  ),  
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary, // Sets the text color
                    ),
                    child: Text(AppStrings.seeAllText),
                  ), 
                ),  
              ],
            ),
          ),

          SizedBox(
            width: 600, // Set width
            // height: MediaQuery.of(context).size.height/3, // Set height 
            height: MediaQuery.of(context).size.height * 0.45,
            child: GridView.builder( 
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent( 
                maxCrossAxisExtent: 150,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1, // Adjust the size ratio of items
              ),
              itemCount: charityLogos.length, // Number of items
              itemBuilder: (context, index) { 
                return LocalCharitiesCard(charityLogo: charityLogos[index]);
              }
            ), 
          ),  
        ],
      ),
    );
    }); 
  }
}
