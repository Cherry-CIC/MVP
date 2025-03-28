import 'dart:io';
 
import 'package:flutter/material.dart';  
 
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart'; 
import 'package:cherry_mvp/features/home/widgets/charity_week_card.dart';
import 'package:cherry_mvp/features/home/widgets/good_news_card.dart';
import 'package:cherry_mvp/features/home/widgets/liked_items.dart'; 
import 'package:cherry_mvp/features/home/widgets/just_for_you.dart'; 
import 'package:cherry_mvp/features/home/widgets/local_charities.dart'; 


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
                    // height: MediaQuery.of(context).size.height*5, 
                    
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
                        CharityWeekCard(),
                        
                        // Good news card 
                        GoodNewsCard(),

                        // Liked items
                        LikedItems(),
 

                        // Just for you
                        JustForYou(),

                        // Local Charities
                        LocalCharities(),

 
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
