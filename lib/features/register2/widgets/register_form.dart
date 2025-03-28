import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';  

import 'package:flutter_phone_number_field/flutter_phone_number_field.dart';
import 'package:flutter_pin_code_fields/flutter_pin_code_fields.dart';
import 'package:flutter/services.dart';

import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/core/router/router.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

 

class _RegisterFormState extends State<RegisterForm> {

  int _index = 0;

  FocusNode focusNode = FocusNode();

  @override 
  Widget build(BuildContext context) { 

    final navigator = Provider.of<NavigationProvider>(context, listen: false);

    return Scaffold( 
      backgroundColor: Colors.white, 
      /* appBar: AppBar( 
        title: Text(
          "Cherry",
          style: TextStyle(color: AppColors.primary, fontSize: 30),
        ), 
        centerTitle: true, 
      ), */
      body: DecoratedBox( 
        // BoxDecoration takes the image
        decoration: BoxDecoration( 
          // Image set to background of the body
          image: DecorationImage( 
            image: AssetImage(AppImages.welcomeBg), 
            fit: BoxFit.cover
          ),
        ),

        child: SingleChildScrollView( 
          child: Column( 
            children: <Widget>[ 
              SizedBox( 
                height: 180, 
              ),
 
              // stepper
              Padding( 
                padding: const EdgeInsets.only(top: 0.0, right:10.0, left:10.0),  
                child: Center( 
                  child: Container( 
                    // alignment: Alignment.center,
                    // width: 300, 
                    // height: 100, 
                    width: double.infinity, 
                    height: MediaQuery.of(context).size.height,
                    // color: AppColors.black,  
                    child: Stepper( 
                      type: StepperType.horizontal, 
                      currentStep: _index,
                      onStepCancel: () {
                        if(_index == 0) {
                          navigator.replaceWith(AppRoutes.welcome);
                        }
                        if (_index > 0) {
                          setState(() {
                            _index -= 1;
                          });
                        }
                      },
                      onStepContinue: () {
                        if(_index == 5) {
                          navigator.replaceWith(AppRoutes.home);
                        }
                        if (_index <= 4) {
                          setState(() {
                            _index += 1;
                          });
                        }
                      },
                      onStepTapped: (int index) {
                        setState(() {
                          _index = index;
                        });
                      },
                      steps: <Step>[

                        // Details
                        Step( 
                          isActive: _index == 0,
                          state: _index == 0 ?  StepState.editing : StepState.indexed,  
  
                          stepStyle: StepStyle(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ), 
                            color: AppColors.primary, 
                            connectorColor: AppColors.primary,
                            connectorThickness: 4,
                            errorColor: AppColors.primary,
                            gradient: LinearGradient(
                              colors: [ 
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            // indexStyle: Theme.of(context).textTheme.headlineLarge,
                          ), 

                          // title: const Text('Details'),
                          title: const Text(''),
          
                          content: Container(
                            // alignment: Alignment.center,
                            child: Column(  
                              children: <Widget>[ 
                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.centerLeft, 
                                      width: double.infinity, 
                                      height: 40.0,    
                                      child: Text(
                                        AppStrings.createAccountText,
                                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.black),
                                      ), 
                                    ), 
                                  ), 
                                ), 

                                Container( 
                                  child: Center(   
                                    child: Row(  
                                      children: [ 
                                        Padding( 
                                          padding: const EdgeInsets.only(left: 15.0, bottom:10.0,), 
                                          child: Text(AppStrings.easyregistrationText), 
                                        ),   
                                      ], 
                                    ), 
                                  ) 
                                ),

                                // First name textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),  
                                  child: TextField(  
                                  style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationPasswordEmail(labelText:"First Name", hintText:"Enter firstname", iconPrefix:Icons.person, passwordInvisible: null, onPressed: () => null) 
                                  ), 
                                ), 

                                // Last name textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),   
                                  child: TextField( 
                                  style: TextStyle(height: 3.0,), 
                                    decoration: buildInputDecorationPasswordEmail(labelText:"Last Name", hintText:"Enter lastname", iconPrefix:Icons.person, passwordInvisible: null, onPressed: () => null) 
                                  ), 
                                ), 
                              ],
                            ), 
                          ),  
                        ),




                        // Email
                        Step( 
                          isActive: _index == 1,
                          state: _index == 1 ?  StepState.editing : StepState.indexed,  
  
                          stepStyle: StepStyle(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ), 
                            color: AppColors.primary, 
                            connectorColor: AppColors.primary,
                            connectorThickness: 4,
                            errorColor: AppColors.primary,
                            gradient: LinearGradient(
                              colors: [ 
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            // indexStyle: Theme.of(context).textTheme.headlineLarge,
                          ),

                          // title: const Text('Email'),
                          title: const Text(''),
          
                          content: Container(
                            // alignment: Alignment.center,
                            child: Column(  
                              children: <Widget>[ 
                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.centerLeft, 
                                      width: double.infinity, 
                                      height: 40.0,   
                                      child: Text(
                                        AppStrings.whatEmailText,
                                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.black),
                                      ), 
                                    ), 
                                  ), 
                                ), 

                                Container( 
                                  child: Center(   
                                    child: Row(  
                                      children: [ 
                                        Padding( 
                                          padding: const EdgeInsets.only(left: 15.0, bottom:40.0,), 
                                          child: Text(AppStrings.verificationCodeText), 
                                        ),   
                                      ], 
                                    ), 
                                  ) 
                                ),

                                // Email textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),  
                                  child: TextField(  
                                  style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationPasswordEmail(labelText:"Email", hintText:"Enter email", iconPrefix:Icons.email, passwordInvisible: null, onPressed: () => null) 
                                  ), 
                                ), 
                              ],
                            ), 
                          ),  
                        ),


                        // Phone number 
                        Step( 
                          isActive: _index == 2,
                          state: _index == 2 ?  StepState.editing : StepState.indexed,  
  
                          stepStyle: StepStyle(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ), 
                            color: AppColors.primary, 
                            connectorColor: AppColors.primary,
                            connectorThickness: 4,
                            errorColor: AppColors.primary,
                            gradient: LinearGradient(
                              colors: [ 
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            // indexStyle: Theme.of(context).textTheme.headlineLarge,
                          ),

                          // title: const Text('Phone'),
                          title: const Text(''),
          
                          content: Container( 
                            child: Column(  
                              children: <Widget>[  

                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container( 
                                          height: 40, 
                                          child: Text(
                                            AppStrings.verifyPhoneText,
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.black),
                                          ),
                                        ),
                                      ), 
                                    ],
                                  ),
                                ),

                                // I have used Row and Expande to make the text responsive
                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container( 
                                          height: 50, 
                                          child: Text(AppStrings.verifyPhoneCodeText),
                                        ),
                                      ), 
                                    ],
                                  ),
                                ),  

                                // Phone number textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 0.0),   
 
                                  child: FlutterPhoneNumberField( 
                                    style: TextStyle(height: 3.0,),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: <TextInputFormatter>[ 
                                       FilteringTextInputFormatter.digitsOnly 
                                    ],
                                    focusNode: focusNode,
                                    initialCountryCode: "GB",
                                    pickerDialogStyle: PickerDialogStyle(
                                      countryFlagStyle: const TextStyle(fontSize: 17),
                                    ), 

                                    decoration: buildInputDecorationPasswordEmail(labelText:"Phone number", hintText:"Enter phone number", iconPrefix:Icons.phone, passwordInvisible: null, onPressed: () => null),

                                    languageCode: "en",
                                    onChanged: (phone) {
                                      if (kDebugMode) {
                                        print(phone.completeNumber);
                                      }
                                    },
                                    onCountryChanged: (country) {
                                      if (kDebugMode) {
                                        print('Country changed to: ${country.name}');
                                      }
                                    },
                                  ), 
                                ),


                                Container( 
                                  child: Center(   
                                    child: Row(  
                                      children: [ 
                                        Padding( 
                                          padding: const EdgeInsets.only(left: 15.0, bottom:0.0,), 
                                          child: Text(AppStrings.dataRateText), 
                                        ),   
                                      ], 
                                    ), 
                                  ) 
                                ), 
                              ],
                            ), 
                          ),  
                        ),




                        // 6-digit code
                        Step( 
                          isActive: _index == 3,
                          state: _index == 3 ?  StepState.editing : StepState.indexed,  
                          
                          // style the step icon, connector 
                          stepStyle: StepStyle(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ), 
                            color: AppColors.primary, 
                            connectorColor: AppColors.primary,
                            connectorThickness: 4,
                            errorColor: AppColors.primary,
                            gradient: LinearGradient(
                              colors: [ 
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            // indexStyle: Theme.of(context).textTheme.headlineLarge,
                          ),

                          // title: const Text('6-digit code'),
                          title: const Text(''),
          
                          content: Container( 
                            child: Column( // const Text('Content for Step 1'), 
                              children: <Widget>[  
                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container( 
                                          height: 40, 
                                          child: Text(
                                            AppStrings.sixDigitCodeText,
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.black),
                                          ),
                                        ),
                                      ), 
                                    ],
                                  ),
                                ), 

                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container( 
                                          height: 50, 
                                          child: Text(AppStrings.verifySixDigitCodeText),
                                        ),
                                      ), 
                                    ],
                                  ),
                                ), 

                                // 6-digit code textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:0.0,right: 0.0,top:20,bottom: 0.0),  
                                  
                                  child: PinCodeFields(
                                    length: 6,
                                    fieldBorderStyle: FieldBorderStyle.square,
                                    responsive: true,
                                    fieldHeight: 70.0,
                                    fieldWidth: 50.0, 
                                    borderWidth: 2.0,
                                    activeBorderColor: AppColors.primary,
                                    activeBackgroundColor: AppColors.white,
                                    borderRadius: BorderRadius.circular(10.0),

                                    // display only the keyboard
                                    keyboardType: TextInputType.number,

                                    // the all the letters and special characters will be disabled
                                    // the user is forced to enter only the numbers
                                    inputFormatters: <TextInputFormatter>[ 
                                       FilteringTextInputFormatter.digitsOnly 
                                    ],
                                    autoHideKeyboard: false,
                                    borderColor: AppColors.primary,
                                    textStyle: TextStyle(
                                      fontSize: 30.0,
                                      fontWeight: FontWeight.bold,
                                    ),

                                    onComplete: (text) { 
                                      print(text);
                                    },
                                  ),
                                  
                                ),


                                Container( 
                                  child: Center(   
                                    child: Row(  
                                      children: [ 
                                        Padding( 
                                          padding: const EdgeInsets.only(left: 15.0, bottom:10.0,), 
                                          child: Text(AppStrings.dataRateText), 
                                        ),   
                                      ], 
                                    ), 
                                  ) 
                                ), 
                              ],
                            ), 
                          ),  
                        ),
                        

                        // Experience 
                        Step( 
                          isActive: _index == 4,
                          state: _index == 4 ?  StepState.editing : StepState.indexed,  
  
                          stepStyle: StepStyle(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ), 
                            color: AppColors.primary, 
                            connectorColor: AppColors.primary,
                            connectorThickness: 4,
                            errorColor: AppColors.primary,
                            gradient: LinearGradient(
                              colors: [ 
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            // indexStyle: Theme.of(context).textTheme.headlineLarge,
                          ), 

                          // title: const Text('Experience'),
                          title: const Text(''),
          
                          content: Container(
                            // alignment: Alignment.center,
                            child: Column( // const Text('Content for Step 1'), 
                              children: <Widget>[  
                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container( 
                                          height: 40, 
                                          child: Text(
                                            AppStrings.experienceText,
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.black),
                                          ),
                                        ),
                                      ), 
                                    ],
                                  ),
                                ), 

                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          // color: Colors.blue,
                                          height: 50,
                                          // child: Center(child: Text(AppStrings.preferenceText)),
                                          child: Text(AppStrings.preferenceText),
                                        ),
                                      ), 
                                    ],
                                  ),
                                ), 
                                //

                                // Date of birth textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0.0,bottom: 10),  
                                  child: TextField(  
                                    style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationPasswordEmail(labelText:"Date of birth (dd/mm/yyyy)", hintText:"Date of birth", iconPrefix:Icons.calendar_today, passwordInvisible: null, onPressed: () => null)
                                  ), 
                                ), 

                                // Gender textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),  
                                  child: TextField(  
                                    style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationPasswordEmail(labelText:"Gender", hintText:"Enter gender", iconPrefix:Icons.person, passwordInvisible: null, onPressed: () => null) 
                                  ), 
                                ), 

                                // Location textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),  
                                  child: TextField(  
                                    style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationPasswordEmail(labelText:"Location", hintText:"Enter location", iconPrefix:Icons.location_on, passwordInvisible: null, onPressed: () => null) 
                                  ), 
                                ), 

                                // Top size textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),  
                                  child: TextField(  
                                    style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationShoeTopBottom(labelText:"Top Sizes", hintText:"Enter top sizes", icon:Icons.keyboard_arrow_up) 
                                  ), 
                                ), 

                                // Bottom size textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),  
                                  child: TextField(  
                                    style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationShoeTopBottom(labelText:"Bottom Sizes", hintText:"Enter bottom sizes", icon:Icons.keyboard_arrow_up) 
                                  ), 
                                ), 

                                // Shoes size textfield
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),  
                                  child: TextField(  
                                    style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationShoeTopBottom(labelText:"Shoes Sizes", hintText:"Enter shoes sizes", icon:Icons.keyboard_arrow_up) 
                                  ), 
                                ), 
                              ],
                            ), 
                          ),  
                        ),


                      
                        // password
                        Step(  
                          isActive: _index == 5,
                          state: _index == 5 ?  StepState.editing : StepState.indexed,  
  
                          stepStyle: StepStyle(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ), 
                            color: AppColors.primary, 
                            connectorColor: AppColors.primary,
                            connectorThickness: 4,
                            errorColor: AppColors.primary,
                            gradient: LinearGradient(
                              colors: [ 
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            // indexStyle: Theme.of(context).textTheme.headlineLarge,
                          ),

                          // title: const Text('Password'),
                          title: const Text(''),

                          content: Container( 
                            child: Column(  
                              children: <Widget>[ 
                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.center,
                                      width: MediaQuery.of(context).size.width,  
                                      height: 2,  
                                    ), 
                                  ), 
                                ),  

                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container( 
                                          height: 40, 
                                          child: Text(
                                            AppStrings.createPasswordText,
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.black),
                                          ),
                                        ),
                                      ), 
                                    ],
                                  ),
                                ), 

                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0, left:15.0,), 
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container( 
                                          height: 50, 
                                          child: Text(AppStrings.protectPasswordText),
                                        ),
                                      ), 
                                    ],
                                  ),
                                ),    
  

                                // Password
                                /* Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0.0,bottom: 0.0),     
                                  child: TextField( 
                                    textAlign: TextAlign.center,
                                    obscureText: true,
                                    obscuringCharacter: '●',
                                    style: TextStyle(fontSize: 20),
                                    decoration: InputDecoration(
                                      hintText: "●●●●●●●●●●●●●",
                                      hintStyle: TextStyle(color: AppColors.greyTextColor, fontSize: 20), // Styling the placeholder 
                                      border: InputBorder.none, // No border
                                    ),
                                  ), 
                                ), */

                                // New password
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),  
                                  child: TextField(  
                                  style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationPasswordEmail(labelText:"New Password", hintText:"Enter new password", iconPrefix:Icons.lock, passwordInvisible: null, onPressed: () => null) 
                                  ), 
                                ),

                                // Confirm new password
                                Padding( 
                                  padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 10),  
                                  child: TextField(  
                                  style: TextStyle(height: 3.0,),
                                    decoration: buildInputDecorationPasswordEmail(labelText:"Confirm New Password", hintText:"Confirm new password", iconPrefix:Icons.lock, passwordInvisible: null, onPressed: () => null) 
                                  ), 
                                ),
                              ],
                            ), 
                          ),   
                        ),
                      ],
 
                      controlsBuilder: (BuildContext context, ControlsDetails details) {
                        return Column( 
                          children: [
                            // Next button
                            SizedBox( 
                              height: 70,  
                              width: double.infinity, 
                              child: Container( 
                                child: Padding( 
                                  padding: const EdgeInsets.only(top: 20.0, right:15.0, left:15.0),  
                                  child: ElevatedButton( 
                                    onPressed: details.onStepContinue,
                                    style: elevatedButtonStyle(context), 
                                    child: Text( 
                                      "Next", 
                                      style: TextStyle(color: AppColors.white, fontSize: 20), 
                                    ),  
                                  ), 
                                ), 
                              ), 
                            ),  

                            SizedBox(height: 20),
                            
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: AppColors.greyTextColor,  ), 
                                ),
                              ), 
                            ),
                          ],
                        );
                      }, 

                    ), 
                  ), 
                ), 
              ),   
            ], 
          ), 
        )
      ), 
    ); 
  } 
}
