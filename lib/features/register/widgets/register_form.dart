import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
                AppStrings.register,
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
              validator: (value) {
                if (value!.isEmpty) return "Email cannot be empty";
                if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]+$")
                    .hasMatch(value)) {
                  return "Please enter a valid email";
                }
                return null;
              },
              decoration: buildInputDecoration(hintText: 'Email', icon: Icons.email),
            ),
            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              validator: (value) {
                if (value!.isEmpty) return "Password cannot be empty";
                if (value.length < 6) return "Password must be at least 6 characters";
                return null;
              },
              decoration:
              buildInputDecoration(hintText: 'Password', icon: Icons.lock),
            ),
            const SizedBox(height: 20),

            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              validator: (value) {
                if (value!.isEmpty) return "Confirm your password";
                if (value != _passwordController.text) {
                  return "Passwords do not match";
                }
                return null;
              },
              decoration: buildInputDecoration(hintText: 'Confirm Password', icon: Icons.lock),
            ),
            const SizedBox(height: 20),

            // Consumer to listen to RegisterViewModel
            Consumer<RegisterViewModel>(
              builder: (context, viewModel, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (viewModel.status.type == StatusType.failure) {
                    Fluttertoast.showToast(
                        msg: viewModel.status.message ?? "");
                  } else if (viewModel.status.type == StatusType.success) {
                    Fluttertoast.showToast(msg: "Registration Successful");

                    // Clear form fields after successful registration
                    _emailController.clear();
                    _passwordController.clear();
                    _confirmPasswordController.clear();

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
                          viewModel.register(
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

            // Login Navigation
            GestureDetector(
              onTap: () {
                 navigator.replaceWith(AppRoutes.login);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?",
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.primary)),
                  const SizedBox(width: 5),
                  Text("Login",
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
