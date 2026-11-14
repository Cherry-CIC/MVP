import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  final _emailFocus = FocusNode();
  final _emailKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => _onFocusChanged(_emailFocus, _emailKey));
  }

  void _onFocusChanged(FocusNode node, GlobalKey key) {
    if (!node.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        alignment: 0.25,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _scrollController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          icon: Image.asset(
            AppImages.backIcon,
            width: 24,
            height: 24,
            excludeFromSemantics: true,
          ),
          onPressed: () {
            context.read<ForgotPasswordViewModel>().clearStatus();
            context.read<ForgotPasswordViewModel>().goBack();
          },
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
                  key: _emailKey,
                  label: AppStrings.email,
                  hint: 'Enter your email',
                  controller: _emailController,
                  validator: validateEmail,
                  prefixIcon: Icons.email,
                  keyboardType: KeyboardType.emailAddress,
                  isLastField: true,
                ),

                const SizedBox(height: 24),

                Consumer<ForgotPasswordViewModel>(
                  builder: (context, viewModel, child) {
                    final isLoading = viewModel.status.type == StatusType.loading;
                    final errorMessage = viewModel.status.type == StatusType.failure
                        ? viewModel.status.message
                        : null;
                    return Column(
                      children: [
                        if (errorMessage != null && errorMessage.isNotEmpty) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              errorMessage,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: isLoading
                              ? Semantics(
                                  button: true,
                                  enabled: false,
                                  liveRegion: true,
                                  label: AppStrings.loadingButton('Send Reset Email'),
                                  excludeSemantics: true,
                                  child: FilledButton(
                                    onPressed: null,
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                )
                              : FilledButton(
                                  onPressed: () async {
                                    final trimmedEmail = _emailController.text.trim();

                                    _emailController.value = _emailController.value.copyWith(
                                      text: trimmedEmail,
                                      selection: TextSelection.collapsed(offset: trimmedEmail.length),
                                    );

                                    if (_formKey.currentState!.validate()) {
                                      final result = await viewModel.sendPasswordResetEmail(trimmedEmail);
                                      if (result.isSuccess) {
                                        Fluttertoast.showToast(
                                          msg: "Reset link sent! Please check your email.",
                                        );
                                        viewModel.clearStatus();
                                        if (context.mounted) {
                                          viewModel.goBack();
                                        }
                                      } else {
                                        Fluttertoast.showToast(
                                          msg: viewModel.status.message ?? "Failed to send reset email",
                                        );
                                      }
                                    }
                                  },
                                  child: const Text("Send Reset Email"),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
