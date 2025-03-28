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

  @override
  void initState() {
    _passwordInvisible = true;
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
            Padding( 
              padding: const EdgeInsets.only(top: 110.0), 
              child: Center( 
                child: Container( 
                  width: 200, 
                  height: 100, 
                  /*decoration: BoxDecoration( 
                    color: Colors.red, 
                    borderRadius: BorderRadius.circular(50.0)),*/
                  child: Image.asset('assets/images/Instagram.png')
                ), 
              ), 
            ), 
            
            // Email
            Padding( 
              //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0), 
              padding: EdgeInsets.symmetric(horizontal: 15), 
              child: TextField(  
                decoration: InputDecoration(
                  labelText: "Email", // Label above the TextField
                  hintText: "Enter email", // Placeholder inside the TextField
                  labelStyle: TextStyle(color: AppColors.primary, fontSize: 18), // Styling the label
                  hintStyle: TextStyle(color: AppColors.greyTextColor, fontSize: 16), // Styling the placeholder
                  border: OutlineInputBorder( // Adds a border around the TextField
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: AppColors.greyTextColor),
                  ),
                  prefixIcon: Icon(Icons.email, color: AppColors.primary), // Icon before input
                  filled: true,
                  fillColor: Colors.grey[100], // Background color
                ), 
              ), 
            ), 
         
            
            // Password
            Padding( 
              //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:10,bottom: 0), 
              // padding: EdgeInsets.symmetric(horizontal: 15), 
              padding: EdgeInsets.only(left:15.0,right: 15.0,top:10,bottom: 0),
              child: TextField(  
                obscureText: _passwordInvisible, // true or false 
                decoration: InputDecoration(
                  labelText: "Password", // Label above the TextField
                  hintText: "Enter password", // Placeholder inside the TextField
                  labelStyle: TextStyle(color: AppColors.primary, fontSize: 18), // Styling the label
                  hintStyle: TextStyle(color: AppColors.greyTextColor, fontSize: 16), // Styling the placeholder
                  border: OutlineInputBorder( // Adds a border around the TextField
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: AppColors.greyTextColor),
                  ),
                  prefixIcon: Icon(
                    Icons.email, 
                    color: AppColors.primary
                  ), // Icon before input
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordInvisible ? Icons.visibility_off : Icons.visibility,
                       color: Theme.of(context).primaryColorDark,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordInvisible = !_passwordInvisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[100], // Background color
                ), 
              ), 
            ), 

            SizedBox( 
              height: 65, 
              width: 360, 
              child: Container( 
                child: Padding( 
                  padding: const EdgeInsets.only(top: 20.0), 
                  child: ElevatedButton( 
                    child: Text( 
                      'Log in ', 
                      style: TextStyle(color: Colors.red, fontSize: 20), 
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
        
            Container( 
              child: Center( 
                child: Row( 
                  children: [ 
                    Padding( 
                      padding: const EdgeInsets.only(left: 62), 
                      child: Text('Forgot your login details? '), 
                    ), 

                    Padding( 
                      padding: const EdgeInsets.only(left:1.0), 
                      child: InkWell( 
                        onTap: (){ 
                          print('hello'); 
                        }, 
                        child: Text(
                          'Get help logging in.', 
                          style: TextStyle(fontSize: 14, color: AppColors.primary),
                        )
                      ), 
                    ) 
                  ], 
                ), 
              ) 
            ) 
          ], 
        ), 
      )), 
    ); 
  } 
}
