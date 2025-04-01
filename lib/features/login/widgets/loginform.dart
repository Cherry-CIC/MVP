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

  final imageNetworkProfile = "https://media-hosting.imagekit.io/db4afa6c86914158/profiles_1.jpg?Expires=1837790841&Key-Pair-Id=K2ZIVPTIP2VGHC&Signature=O0MhXhy4IY4Ma-tQB9kU-JKjQ6LpysybQAgnB7JOBzpySZFjW8xzt7hsyZlrnR8zvN41f1mWkBzdIqFlzrBAoQWAHokaeWCwQFx-rgQoxeU5rx2QtYFhUKR-ZZ78~jqYGhNxnA2X4pWzjHQBHMWis7WzgJJXMG1lMWoDo8WAQrPCx0TBFbui50cDRTJAbJtxokouU5kWEYX4MbGD70akXbi-IonInmJ0aE0E6QwCSqz0BtHuFX~P0ufyc5DQNmSWAVSjHc7HNEAA-q~Fjl1MLPZ59Sj4sUB~8lIWuyk-bwV3DAP53YObi6yXCI~Ob0Vkz~-XzVN-m-dJ6m5br-bAtg__";

  int _index = 0;

  @override 
  Widget build(BuildContext context) { 

    final navigator = Provider.of<NavigationProvider>(context, listen: false);

    return Scaffold( 
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
 
              // stepper
              Padding( 
                padding: const EdgeInsets.only(top: 30.0, right:10.0, left:10.0
                ),  
                child: Center( 
                  child: Container(  
                    width: double.infinity, 
                    height: MediaQuery.of(context).size.height, 
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
                            child: Column( 
                              children: <Widget>[ 
                                Padding( 
                                  padding: const EdgeInsets.only(top: 130.0,  
                                  ), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.centerLeft, 
                                      width: double.infinity, 
                                      height: 70.0,    
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
                                          padding: const EdgeInsets.only( 
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
                                  padding: const EdgeInsets.only(
                                  top:20,bottom: 10),  
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
                                        backgroundImage: NetworkImage(imageNetworkProfile),  
                                      ),
                                    ),
                                  )
                                ),
 
                                Padding( 
                                  padding: const EdgeInsets.only(top: 0.0), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.center,
                                      width: MediaQuery.of(context).size.width, // 200, 
                                      height: 30,    
                                      child: Text(
                                        AppStrings.hello,
                                        style: TextStyle(fontSize: 20, color: AppColors.black),
                                      ), 
                                    ), 
                                  ), 
                                ),  

                                Padding( 
                                  padding: const EdgeInsets.only(top: 30.0), 
                                  child: Center( 
                                    child: Container( 
                                      alignment: Alignment.center,
                                      width: MediaQuery.of(context).size.width, 
                                      height: 30,    
                                      child: Text(
                                        AppStrings.typePassword,
                                        style: TextStyle(fontSize: 20, color: AppColors.black),
                                      ), 
                                    ), 
                                  ), 
                                ),  
  

                                // Password
                                Padding( 
                                  padding: const EdgeInsets.only(
                                  top:0.0, bottom: 100.0),    
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
                                    _index == 0 ? 
                                    SizedBox( 
                                      height: 70,  
                                      width: double.infinity, 
                                      child: Container( 
                                        child: Padding( 
                                          padding: const EdgeInsets.only(
                                            top: 20.0, 
                                          ),  
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
                                    :  
                                    viewModel.status.type == StatusType.loading
                                    ? const LoadingView()
                                    : 
                                    Padding( 
                                      padding: const EdgeInsets.only(
                                        top: 20.0, 
                                      ),  
                                      child: PrimaryAppButton(
                                        onPressed: details.onStepContinue, /* () {
                                          if (_formKey.currentState!.validate()) {
                                            viewModel.login(
                                              _emailController.text,
                                              _passwordController.text,
                                            );
                                          }
                                        }, */ 
                                        buttonText: "Submit",
                                      ), 
                                    ),
                                  ],
                                ); 
                              },
                            ), 
                             

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
