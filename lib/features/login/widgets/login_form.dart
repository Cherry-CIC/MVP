import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/welcome/widgets/auth_form_shell.dart';
import 'package:cherry_mvp/features/shared_widgets/labeled_input_field.dart';

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

  final _scrollController = ScrollController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => _onFocusChanged(_emailFocus, _emailKey));
    _passwordFocus.addListener(() => _onFocusChanged(_passwordFocus, _passwordKey));
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
    _passwordFocus.dispose();
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Provider.of<NavigationProvider>(context, listen: false);

    return AuthFormShell(
      scrollController: _scrollController,
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Email Field
              LabeledInputField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                validator: validateEmail,
                prefixIcon: Icons.email,
                keyboardType: KeyboardType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Password Field
              LabeledInputField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                validator: validatePassword,
                prefixIcon: Icons.lock,
                obscureText: true,
                isLastField: true,
              ),

              const SizedBox(height: 16),

              Consumer<LoginViewModel>(
                builder: (context, viewModel, child) {
                  return Column(
                    children: [
                      viewModel.status.type == StatusType.loading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () async {
                                  final trimmedEmail = _emailController.text.trim();

                                  _emailController.value = _emailController.value.copyWith(
                                    text: trimmedEmail,
                                    selection: TextSelection.collapsed(offset: trimmedEmail.length),
                                  );

                                  if (_formKey.currentState!.validate()) {
                                    await viewModel.login(
                                      trimmedEmail,
                                      _passwordController.text,
                                    );
                                    if (viewModel.status.type == StatusType.success) {
                                      Fluttertoast.showToast(msg: "Login Successful");
                                    } else {
                                      Fluttertoast.showToast(msg: viewModel.status.message ?? "");
                                    }
                                  }
                                },
                                child: const Text("Submit"),
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
                  onPressed: () {},
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
      ),
    );
  }
}
