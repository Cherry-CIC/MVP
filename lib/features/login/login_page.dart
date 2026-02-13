import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/login/widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(
            AppImages.backIcon,
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Login'),
      ),
      body: const LoginForm(),
    );
  }
}
