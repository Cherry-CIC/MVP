import 'dart:io';
 
import 'package:flutter/material.dart';  
 
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart'; 
import 'package:cherry_mvp/features/home/widgets/charity_week_card.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

 

class HomeScreenState extends State<HomeScreen> { 

  @override 
  Widget build(BuildContext context) { 
    
    // const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold,);

    return Scaffold( 
      backgroundColor: Colors.white, 
      /* appBar: AppBar( 
        title: Text(
          "Cherry",
          style: TextStyle(color: AppColors.primary, fontSize: 30, width:30),
        ), 
        centerTitle: true, 
      ), */
      body: DecoratedBox( 
        // BoxDecoration takes the image
        decoration: BoxDecoration( 
          // Image set to background of the body
          image: DecorationImage( 
            image: AssetImage(AppImages.welcomeBg), 
            fit: BoxFit.fill
          ),
        ),
        child: SingleChildScrollView( 
          child: Column( 
            children: <Widget>[ 
              SizedBox( 
                height: 35, 
              ),   

              // Beginning first child in the scroll view
              Padding(
                padding: const EdgeInsets.only(top: 0.0, right:1.0, left:1.0),  
                child: Center(
                  child: Container(
                    width: double.infinity, 
                    height: MediaQuery.of(context).size.height,
                    
                    // another column
                    child: Column(
                      children: <Widget>[ 

                        // Search textfield
                        Padding( 
                          padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0.0,bottom: 20),  
                          child: TextField( 
                            style: TextStyle(height: 1.0,), 
                            decoration: buildInputDecorationShoeTopBottom(labelText:"Search: 'Red Dress'", hintText:"", icon:Icons.camera_alt_rounded, enabledBorderRadiusValue:50.0, iconColor: AppColors.primary) 
                          ), 
                        ),  
                        //

                        // Charity of the week card layout
                        Padding( 
                          padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0.0,bottom: 10),  
                          child: Card( 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // Set border radius
                            ), 

                            child: Stack(
                              children: [
                                // Background Image  
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(
                                    AppImages.redBackground, // Replace with your image path
                                    width: double.infinity,
                                    height: 200, // Adjust height as needed
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
                                      padding: const EdgeInsets.only(top: 0.0, left:15.0,),  
                                      child: Row(
                                        // mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                        children: [
                                          Expanded(
                                            child: Container( 
                                              height: 30, 
                                              child: Text(
                                                AppStrings.charityOfText,
                                                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, color: AppColors.white),
                                              ),  
                                            ),
                                          ),  

                                        ],
                                      ),
                                    ),  

                                    //  text  the week  
                                    Padding( 
                                      padding: const EdgeInsets.only(top: 0.0, left:15.0, bottom:0.0, ),  
                                      child: Row(
                                        // mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                        children: [
                                          Expanded(
                                            child: Container( 
                                              height: 25, 
                                              child: Text(
                                                AppStrings.weekText,
                                                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, color: AppColors.white),
                                              ),  
                                            ),
                                          ), 
                                        ],
                                      ),
                                    ), 


                                    Padding( 
                                      padding: const EdgeInsets.only(top: 30.0, left:15.0, bottom:0.0, ),  
                                      child: Row(
                                        // mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                        children: [
                                          Expanded(
                                            child: Container( 
                                              height: 20, 
                                              child: Text(
                                                AppStrings.browseItemsText,
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.white),
                                              ),  
                                            ),
                                          ), 
                                        ],
                                      ),
                                    ),   

                                    Padding( 
                                      padding: const EdgeInsets.only(top: 0.0, left:15.0, bottom:0.0, ),  
                                      child: Row(
                                        // mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                        children: [
                                          Expanded(
                                            child: Container( 
                                              height: 20, 
                                              child: Text(
                                                AppStrings.learMoreText,
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.white),
                                              ),  
                                            ),
                                          ), 
                                        ],
                                      ),
                                    ),     

                                    Padding( 
                                      padding: const EdgeInsets.only(top: 0.0, left:15.0, bottom:0.0, ),  
                                      child: Row(
                                        // mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                        children: [
                                          Expanded(
                                            child: Container( 
                                              height: 20, 
                                              child: Text(
                                                AppStrings.workHereText,
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.white),
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
                        ),  
                        //
                      ],
                    ),
                  ),
                ),
              ),
              // End first child in the scroll view

            ],
          ),
        ),
      ),
    ); 
  } 
}
