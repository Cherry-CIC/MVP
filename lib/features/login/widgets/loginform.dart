import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:sign_in_button/sign_in_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final navigator = Provider.of<NavigationProvider>(context, listen: false);

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                AppStrings.login,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.black),
              ),
            ),
            const SizedBox(height: 20),

            // Email Field
            TextFormField(
              controller: _emailController,
              validator: validateEmail,
              decoration:
                  buildInputDecoration(hintText: 'Email', icon: Icons.email),
            ),
            const SizedBox(height: 10),

            // Password Field
            TextFormField(
              controller: _passwordController,
              validator: validatePassword,
              decoration:
                  buildInputDecoration(hintText: 'Password', icon: Icons.lock),
            ),
            const SizedBox(height: 10),

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

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        navigator.replaceWith(AppRoutes.home);
                      },
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Text(AppStrings.forgotPassword,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.primary)),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
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
                            buttonText: AppStrings.login,
                          ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Divider(),
                ),
                SizedBox(
                  width: 15,
                ),
                Text("OR"),
                SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Divider(),
                )
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // Social login buttons
            SizedBox(
              width: AppMeasurements.getScreenWidth(context),
              height: 45,
              child: SignInButton(
                Buttons.google,
                onPressed: () {
                  print("Login with google");
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                text: "Login with Google",
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            SizedBox(
              width: AppMeasurements.getScreenWidth(context),
              height: 45,
              child: SignInButton(
                Buttons.apple,
                onPressed: () {
                  print("Login with apple");
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                text: "Login with Apple",
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // Sign Up Navigation
            GestureDetector(
              onTap: () {
                navigator.replaceWith(AppRoutes.register);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? "),
                  Text(AppStrings.register,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
