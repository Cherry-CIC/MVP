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

  bool _passwordInvisible = true; 
  bool? value = true;

  @override
  void initState() {
    _passwordInvisible = true; 
  }

  onPressed() {
    setState(() {
      _passwordInvisible = !_passwordInvisible;
    });
  }

  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      backgroundColor: Colors.white, 
      appBar: AppBar( 
        title: Text(
          "Cherry",
          style: TextStyle(color: AppColors.primary, fontSize: 30),
        ), 
        centerTitle: true, 
      ),  
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
              // Text welcome
              Padding( 
                padding: const EdgeInsets.only(top: 20.0), 
                child: Center( 
                  child: Container( 
                    alignment: Alignment.center,
                    width: 200, 
                    height: 100,  
                    // color: AppColors.black,  
                    child: Text(
                      AppStrings.welcome,
                      style: TextStyle(fontSize: 30, color: AppColors.black),
                    ), 
                  ), 
                ), 
              ), 
              
              // Text login to Cherry
              Padding( 
                padding: const EdgeInsets.only(top: 1.0), 
                child: Center( 
                  child: Container( 
                    alignment: Alignment.center,
                    width: 300, 
                    height: 50,  
                    // color: AppColors.black,  
                    child: Text(
                      AppStrings.loginCherry,
                      style: TextStyle(fontSize: 20, color: AppColors.black),
                    ), 
                  ), 
                ), 
              ), 
            
              // Email
              Padding( 
                //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0), 
                padding: EdgeInsets.symmetric(horizontal: 15), 
                child: TextField(  
                  decoration: buildInputDecorationPasswordEmail(labelText:"Email", hintText:"Enter email", iconPrefix:Icons.email, passwordInvisible: null, onPressed: () => null) 
                ), 
              ), 

              // Password
              Padding(  
                // padding: EdgeInsets.symmetric(horizontal: 15), 
                padding: EdgeInsets.only(left:15.0,right: 15.0,top:10,bottom: 0),
                child: TextField(  
                  obscureText: _passwordInvisible, // true or false 
                  decoration: buildInputDecorationPasswordEmail(labelText:"Password", hintText:"Enter password", iconPrefix:Icons.lock, passwordInvisible: _passwordInvisible, onPressed: onPressed) 
                ), 
              ),
              
              // forgot password text
              Container( 
                child: Center( 
                  child: Row( 
                    children: [ 
                      /* Padding( 
                        padding: const EdgeInsets.only(left: 62), 
                        child: Text(AppStrings.dontHaveAccount), 
                      ), */

                      Padding( 
                        padding: const EdgeInsets.only(left:15.0, top:10.0), 
                        child: InkWell( 
                          onTap: (){ 
                            print('hello'); 
                          }, 
                          child: Text(
                            AppStrings.forgotPassword, 
                            style: TextStyle(fontSize: 14, color: AppColors.primary),
                          )
                        ), 
                      ) 
                    ], 
                  ), 
                ) 
              ), 
              
              // checkbox remember me
              Container( 
                child: Center( 
                  child: Row( 
                    children: [ 
                      Padding( 
                        padding: const EdgeInsets.only(left: 62), 
                        child: Text(AppStrings.rememberMe), 
                      ), 

                      Padding( 
                        padding: const EdgeInsets.only(left:15.0, top:10.0), 
                        child: Checkbox(
                          tristate: false, // Example with tristate
                          value: value,
                          activeColor: AppColors.primary,
                          onChanged: (bool? newValue) {
                            setState(() {
                              value = newValue;
                            });
                          },
                        ),
                      ) 
                    ], 
                  ), 
                ) 
              ), 
              
              // login to continue
              SizedBox( 
                height: 65, 
                // width: 360,
                width: double.infinity, 
                child: Container( 
                  child: Padding( 
                    padding: const EdgeInsets.only(top: 20.0, right:15.0, left:15.0), 
                    // padding: EdgeInsets.symmetric(horizontal: 15),
                    child: ElevatedButton( 
                      style: ElevatedButton.styleFrom(
                        backgroundColor:  AppColors.primary,
                      ), 
                      child: Text( 
                        AppStrings.loginToContinue, 
                        style: TextStyle(color: AppColors.white, fontSize: 20), 
                      ), 
                      onPressed: (){ 
                        print('Successfully log in '); 
                      }, 
                    ), 
                  ), 
                ), 
              ), 

              SizedBox( 
                height: 50, 
              ), 
              
              // text don't have an account
              Container( 
                child: Center( 
                  child: Row( 
                    children: [ 
                      Padding( 
                        padding: const EdgeInsets.only(left: 62), 
                        child: Text(AppStrings.dontHaveAccount), 
                      ), 

                      Padding( 
                        padding: const EdgeInsets.only(left:1.0), 
                        child: InkWell( 
                          onTap: (){ 
                            print('hello'); 
                          }, 
                          child: Text(
                            AppStrings.register, 
                            style: TextStyle(fontSize: 14, color: AppColors.primary),
                          )
                        ), 
                      ) 
                    ], 
                  ), 
                ) 
              ),

              SizedBox( 
                height: 20, 
              ), 
              
              // the text or between the dividers
              Container( 
                child: Center( 
                  child: Row( 
                    children: [ 
                      Expanded(
                        child: new Container(
                          margin: const EdgeInsets.only(left: 15.0, right: 2.0),
                          child: Divider(
                            color: AppColors.black,
                            height: 36,
                          )
                        ),
                      ),
                      Padding( 
                        padding: const EdgeInsets.only(left: 0.0), 
                        child: Text(AppStrings.or), 
                      ), 
                      Expanded(
                        child: new Container(
                          margin: const EdgeInsets.only(left: 2.0, right: 15.0),
                          child: Divider(
                            color: AppColors.black,
                            height: 36,
                          )
                        ),
                      ),
                      
                    ], 
                  ), 
                ) 
              ),

              SizedBox( 
                height: 20, 
              ), 
              
              // Sign in with Apple
              SizedBox( 
                height: 65, 
                width: 360, 
                child: Container( 
                  child: Padding( 
                    padding: const EdgeInsets.only(top: 0.0),  
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.apple, size:50, color:AppColors.primary),
                      label: const Text(
                        AppStrings.signInApple, 
                        style: TextStyle(color: AppColors.primary),
                      ),
                      iconAlignment: IconAlignment.start,
                    ), 
                  ), 
                ), 
              ), 
              

              SizedBox( 
                height: 20, 
              ), 
              
              // Sign in with Google
              SizedBox( 
                height: 65, 
                width: 360, 
                child: Container( 
                  child: Padding( 
                    padding: const EdgeInsets.only(top: 0.0),  
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.android, size:50, color:AppColors.primary),
                      label: const Text(
                        AppStrings.signInGoogle, 
                        style: TextStyle(color: AppColors.primary),
                      ),
                      iconAlignment: IconAlignment.start,
                    ), 
                  ), 
                ), 
              ), 

              SizedBox( 
                height: 50, 
              ), 

              //


            ], 
          ), 
        )
      ), 
    ); 
  } 
}
