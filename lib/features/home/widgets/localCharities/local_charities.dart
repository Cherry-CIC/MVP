import 'dart:io';

import 'package:flutter/material.dart';
import 'package:auto_height_grid_view/auto_height_grid_view.dart';

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
          padding: const EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, ),
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
                        AppStrings.localCharitiesText,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.black),
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
                        child: Text(AppStrings.seeAllLocalCharitiesText),
                      ), 
                    ),  
                  ],
                ),
              ),
 
              Center(
                child: Container( 
                  width: 600, // Set width  

                  child:AutoHeightGridView(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1, 

                    itemCount: charityLogos.length,
                    shrinkWrap: true, // Ensures the GridView takes only necessary space
                    physics: const BouncingScrollPhysics(),

                    builder: (context, index) {
                      return LocalCharitiesCard(charityLogo: charityLogos[index]);
                    }
                  ), 
                ),
              ), 
            ],
          ),
        );
      }
    ); 
  }
}
