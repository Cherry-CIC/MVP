import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            // Password Field
            TextFormField(
              controller: _passwordController,
              validator: validatePassword,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
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
                    viewModel.status.type == StatusType.loading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  viewModel.login(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                                }
                              },
                              child: Text("Submit"),
                            ),
                          ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => navigator.replaceWith(AppRoutes.register),
                child: Text(AppStrings.createAccount),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // navigator.replaceWith(AppRoutes.home);
                },
                child: Center(
                  child: Text(
                    AppStrings.forgotPassword,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
