import 'package:flutter/material.dart';    
 
import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';  


class SuccessfulUploadPage extends StatelessWidget {
  const SuccessfulUploadPage({super.key});   


  @override 
  Widget build(BuildContext context) {    
    double screenHeight = MediaQuery.of(context).size.height; 
  
    return Scaffold(
      backgroundColor: Colors.white,   
      
      body: Stack( 
        children:[ 
          Center(
            child: Column( 
              children: [
                Padding(padding: EdgeInsets.symmetric(vertical:screenHeight*0.15),),

                Container(
                  width: 80, 
                  height: 80,  
                  child: Card(
                    color: AppColors.primary,  
                    elevation:4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),  
                      side: BorderSide(
                        color: AppColors.white,  
                        width: 12, 
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical:10.0, horizontal:10.0), 
                      child: Icon(
                        Icons.check, 
                        color: AppColors.white,  
                        size: 30,           
                      ),
                    ), 
                  ),     
                ), 

                Padding(padding: EdgeInsets.symmetric(vertical:5.0),),
 
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Congratulations!',
                      style: TextStyle(color: AppColors.black, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ]
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Your Item has been Successfully Uploaded.',
                      style: TextStyle(color: AppColors.black, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ]
                ), 
              ]
            )
          ),


          // Button Continue
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: PrimaryAppButton(
                onPressed: () {},
                buttonText: AppStrings.continueText,
              ),
            ),   
          ),

        ],
      ), 
    );
  } 
}


 