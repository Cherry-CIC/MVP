import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/features/shared_widgets/labeled_input_field.dart';
import 'package:cherry_mvp/features/welcome/widgets/auth_form_shell.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  bool isUsernameChecking = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _scrollController = ScrollController();
  final _userNameFocus = FocusNode();
  final _firstNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  final _userNameKey = GlobalKey();
  final _firstNameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _passwordKey = GlobalKey();
  final _confirmPasswordKey = GlobalKey();

  // Image picker controller
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _userNameFocus.addListener(
      () => _onFocusChanged(_userNameFocus, _userNameKey),
    );
    _firstNameFocus.addListener(
      () => _onFocusChanged(_firstNameFocus, _firstNameKey),
    );
    _emailFocus.addListener(() => _onFocusChanged(_emailFocus, _emailKey));
    _phoneFocus.addListener(() => _onFocusChanged(_phoneFocus, _phoneKey));
    _passwordFocus.addListener(
      () => _onFocusChanged(_passwordFocus, _passwordKey),
    );
    _confirmPasswordFocus.addListener(
      () => _onFocusChanged(_confirmPasswordFocus, _confirmPasswordKey),
    );
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
    _userNameFocus.dispose();
    _firstNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _scrollController.dispose();
    _userNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
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
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: _selectedImage == null
                      ? Container(
                          height: 100,
                          width: 100,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          child: Center(
                            child: Icon(
                              Icons.camera_alt,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                      : Image.file(
                          _selectedImage!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Username Field
              LabeledInputField(
                label: 'Username',
                hint: 'Enter your username',
                controller: _userNameController,
                validator: validateUsername,
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 20),

              // FirstName Field
              LabeledInputField(
                label: 'First Name',
                hint: 'Enter your first name',
                controller: _firstNameController,
                validator: validateFirstName,
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 20),

              // Email Field
              LabeledInputField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                validator: validateEmail,
                prefixIcon: Icons.email,
                keyboardType: KeyboardType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Phone Number
              LabeledInputField(
                label: 'Phone Number',
                hint: 'Enter your phone number',
                controller: _phoneNumberController,
                validator: validatePhoneNumber,
                prefixIcon: Icons.phone,
                keyboardType: KeyboardType.phoneNo,
              ),
              const SizedBox(height: 20),

              // Password Field
              LabeledInputField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                validator: validatePassword,
                prefixIcon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              LabeledInputField(
                label: 'Confirm Password',
                hint: 'Confirm your password',
                controller: _confirmPasswordController,
                validator: (value) => validateConfirmPassword(value, _passwordController.text),
                prefixIcon: Icons.lock,
                obscureText: true,
                isLastField: true,
              ),
              const SizedBox(height: 20),

              Consumer<RegisterViewModel>(
                builder: (context, viewModel, child) {
                  return Column(
                    children: [
                      viewModel.status.type == StatusType.loading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    await viewModel.register(
                                      _firstNameController.text,
                                      _emailController.text,
                                      _userNameController.text,
                                      _phoneNumberController.text,
                                      _passwordController.text,
                                      _selectedImage,
                                    );
                                    if (viewModel.status.type == StatusType.failure) {
                                      Fluttertoast.showToast(msg: viewModel.status.message ?? "");
                                    } else if (viewModel.status.type == StatusType.success) {
                                      Fluttertoast.showToast(msg: "Registration Successful");
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
              const SizedBox(height: 20),
              // Login Navigation
              GestureDetector(
                onTap: () {
                  navigator.replaceWith(AppRoutes.login);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    Text(
                      "Login",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
