import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/welcome/widgets/email_action_page.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/forgot_password/forgot_password_viewmodel.dart';
import 'package:cherry_mvp/features/welcome/widgets/auth_form_shell.dart';
import 'package:cherry_mvp/features/shared_widgets/labeled_input_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final _scrollController = ScrollController();
  String? _confirmationEmail;
  String? _error;

  Future<void> _submit() async {
    final viewModel = context.read<ForgotPasswordViewModel>();
    if (viewModel.status.type == StatusType.loading) return;
    final email = _emailController.text.trim();
    _emailController.text = email;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final result = await viewModel.sendPasswordResetEmail(email);
    if (!mounted || ModalRoute.isCurrentOf(context) != true) return;
    setState(() {
      if (result.isSuccess) {
        _confirmationEmail = email;
      } else {
        _error = result.error ?? 'Unable to send reset email. Please try again.';
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _confirmationEmail;
    if (email != null) {
      return EmailActionPage(
        title: 'Check your email',
        email: email,
        message:
            'If there’s a cherry account linked to this address, you’ll receive a password reset link. Check your inbox and junk folder, then open the link to choose a new password.',
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to login'),
          ),
        ],
      );
    }
    final sending = context.watch<ForgotPasswordViewModel>().status.type == StatusType.loading;
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
        title: const Text('Reset Password'),
      ),
      body: AuthFormShell(
        scrollController: _scrollController,
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Instructions label
                Text(
                  AppStrings.forgotPasswordInstruction,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 24),

                // Email Field
                LabeledInputField(
                  label: AppStrings.email,
                  hint: 'Enter your email',
                  controller: _emailController,
                  validator: validateEmail,
                  prefixIcon: Icons.email,
                  keyboardType: KeyboardType.emailAddress,
                  isLastField: true,
                ),

                const SizedBox(height: 24),

                if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: sending ? null : _submit,
                    child: Text(sending ? 'Sending…' : 'Send Reset Email'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
