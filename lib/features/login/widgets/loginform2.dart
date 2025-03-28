import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/core/router/router.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key}); 
 

  @override
  LoginFormState createState() {
    return LoginFormState();
  }
}

class LoginFormState extends State<LoginForm> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _index = 0;

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
            fit: BoxFit.none
          ),
        ),

        child: SingleChildScrollView( 
               child: Form(
               key: _formKey,
          child: Column( 
            children: <Widget>[ 
              /* SizedBox( 
                height: 180, 
              ), */
 
              // stepper
              Padding( 
                padding: const EdgeInsets.only(top: 30.0, right:10.0, left:10.0
                ),  
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
                        if(_index == 1) {
                          navigator.replaceWith(AppRoutes.home);
                        }
                        if (_index <= 0) {
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
                        Step(
                          title: const Text('Email'),
          
                          content: Container(
                            // alignment: Alignment.center,
                            child: Column( // const Text('Content for Step 1'), 
                              children: <Widget>[ 
                                Padding( 
                                  padding: const EdgeInsets.only(top: 130.0, // left:15.0,
                                  ), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.centerLeft,
                                      // width: 200, 
                                      width: double.infinity, 
                                      height: 70.0,  
                                      // color: AppColors.black,  
                                      child: Text(
                                        AppStrings.login,
                                        style: TextStyle(fontSize: 50, fontWeight: FontWeight.w700, color: AppColors.black),
                                      ), 
                                    ), 
                                  ), 
                                ), 

                                Container( 
                                  child: Center(   
                                    child: Row(  
                                      children: [ 
                                        Padding( 
                                          padding: const EdgeInsets.only(// left: 15.0, 
                                          bottom:40.0,), 
                                          child: Text(AppStrings.goodSeeYou), 
                                        ),  

                                        Padding( 
                                          padding: const EdgeInsets.only(left: 15.0, bottom:40.0,), 
                                          child: Icon(Icons.favorite, color: AppColors.primary), 
                                        ), 
                                      ], 
                                    ), 
                                  ) 
                                ),

                                // Email
                                Padding( 
                                  padding: const EdgeInsets.only(// left:15.0,right: 15.0,
                                  top:20,bottom: 10), 
                                  // padding: EdgeInsets.symmetric(horizontal: 15), 
                                  child: TextFormField(  
                                    controller: _emailController,
                                    validator: validateEmail,
                                    decoration: buildInputDecorationPasswordEmail(labelText:"Email", hintText:"Enter email", iconPrefix:Icons.email, passwordInvisible: null, onPressed: () => null) 
                                  ), 
                                ), 
                              ],
                            ), 
                          ),  
                        ),

                      
                        // password
                        Step(
                          title: const Text('Password'), 
                          content: Container(
                            // alignment: Alignment.center,
                            child: Column( // const Text('Content for Step 1'), 
                              children: <Widget>[ 
                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.center,
                                      width: MediaQuery.of(context).size.width, // 200, 
                                      height: 2,  
                                    ), 
                                  ), 
                                ),    

                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0), 
                                  child:Center(
                                    child: Container(
                                      width: 100, // Set the width of the circular avatar
                                      height: 100, // Set the height (same as width to keep it circular)
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle, // Make the container circular
                                      ),
                                      child: CircleAvatar(
                                        radius: 60, // Circle avatar's radius (half the container width/height)
                                        backgroundImage: AssetImage(AppImages.profiles1), // 
                                      ),
                                    ),
                                  )
                                ),

                                // 
                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.center,
                                      width: MediaQuery.of(context).size.width, // 200, 
                                      height: 30,  
                                      // color: AppColors.black,  
                                      child: Text(
                                        AppStrings.hello,
                                        style: TextStyle(fontSize: 20, color: AppColors.black),
                                      ), 
                                    ), 
                                  ), 
                                ),  
                                //

                                Padding( 
                                  padding: const EdgeInsets.only(top: 30.0), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.center,
                                      width: MediaQuery.of(context).size.width, // 200, 
                                      height: 30,  
                                      // color: AppColors.black,  
                                      child: Text(
                                        AppStrings.typePassword,
                                        style: TextStyle(fontSize: 20, color: AppColors.black),
                                      ), 
                                    ), 
                                  ), 
                                ),  
  

                                // Password
                                Padding( 
                                  padding: const EdgeInsets.only(// left:15.0,right: 15.0,
                                  top:0.0, bottom: 100.0), 
                                  // padding: EdgeInsets.symmetric(horizontal: 15),   
                                  child: TextFormField( 
                                    controller: _passwordController,
                                    validator: validatePassword,
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
                            // Consumer to listen to LoginViewModel
                            Consumer<LoginViewModel>(
                              builder: (context, viewModel, child) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (viewModel.status.type == StatusType.failure) {
                                    Fluttertoast.showToast(msg: viewModel.status.message ?? "");
                                  } else if (viewModel.status.type == StatusType.success) {
                                    Fluttertoast.showToast(msg: "Login Successful");
                                    //move to home
                                    navigator.replaceWith(AppRoutes.home);
                                  }
                                });

                                // beginning return
                                return Column(
                                  children: [
                                    /* viewModel.status.type == StatusType.loading
                                    ? const LoadingView()
                                    : PrimaryAppButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          viewModel.login(
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                        }
                                      },
                                      buttonText: "Submit",
                                    ), */

                                    //
                                    _index == 0 ?
                                    // beginning sizedbox
                                    SizedBox( 
                                      height: 70, 
                                      // width: 360,
                                      width: double.infinity, 
                                      child: Container( 
                                        child: Padding( 
                                          padding: const EdgeInsets.only(
                                            top: 20.0, // right:15.0, left:15.0
                                          ), 
                                          // padding: EdgeInsets.symmetric(horizontal: 15),
                                          child: ElevatedButton( 
                                            onPressed: details.onStepContinue,
                                            style: elevatedButtonStyle(context), 
                                            child: Text( 
                                              "Next", 
                                               style: TextStyle(color: AppColors.white, fontSize: 13), 
                                            ),  
                                          ), 
                                        ), 
                                      ), 
                                    )
                                    // end sizedbox
                                    : 
                                    // beginning submit button
                                    viewModel.status.type == StatusType.loading
                                    ? const LoadingView()
                                    : PrimaryAppButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          viewModel.login(
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                        }
                                      },
                                      buttonText: "Submit",
                                    ),
                                    // end submit button
                                  ],
                                );
                                // end return
                              },
                            ),
                            //
                             

                            SizedBox(height: 20),
                            
                            TextButton(
                              onPressed: details.onStepCancel,
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.lightGreyTextColor, // Set the background color
                              ),
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
        ))
      ), 
    ); 
  } 
}
