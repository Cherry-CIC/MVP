import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/register/widgets/register_form.dart';
import 'package:cherry_mvp/l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.authRegisterTitle),
      ),
      body: const RegisterForm(),
    );
  }
}
