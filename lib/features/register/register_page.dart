import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/register/widgets/register_form.dart';

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
          onPressed: () => context.read<RegisterViewModel>().goBack(),
        ),
        title: const Text('Register'),
      ),
      body: const RegisterForm(),
    );
  }
}
