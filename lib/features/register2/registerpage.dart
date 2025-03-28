import 'package:cherry_mvp/features/register/widgets/register_form.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgColor,
      body: RegisterForm(),
    );
  }
}
