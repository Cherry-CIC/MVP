import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/register/widgets/register_form.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

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
        title: const Text('Register'),
      ),
      body: const RegisterForm(),
    );
  }
}
