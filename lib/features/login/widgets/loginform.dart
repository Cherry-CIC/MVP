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
            const SizedBox(height: 28),

            // Email Field
            TextFormField(
              controller: _emailController,
              validator: validateEmail,
              decoration:
              buildInputDecoration(hintText: 'Email', icon: Icons.email),
            ),
            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _passwordController,
              validator: validatePassword,
              decoration:
              buildInputDecoration(hintText: 'Password', icon: Icons.lock),
            ),
            const SizedBox(height: 20),

            // Consumer to listen to LoginViewModel
            Consumer<LoginViewModel>(
              builder: (context, viewModel, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (viewModel.status.type == StatusType.failure) {
                    Fluttertoast.showToast(
                        msg: viewModel.status.message ?? "");
                  } else if (viewModel.status.type == StatusType.success) {
                    Fluttertoast.showToast(msg: "Login Successful");
                    //move to home
                    navigator.replaceWith(AppRoutes.home);
                  }
                });

                return Column(
                  children: [
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
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Sign Up Navigation
            GestureDetector(
              onTap: () {
               navigator.replaceWith(AppRoutes.register);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.create_account,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Forgot Password
            GestureDetector(
              onTap: () {
               navigator.replaceWith(AppRoutes.home);
              },
              child: Center(
                child: Text(AppStrings.forgotPassword,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
