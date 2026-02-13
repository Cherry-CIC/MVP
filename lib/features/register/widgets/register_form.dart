import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/welcome/widgets/auth_form_shell.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  bool isUsernameChecking = false;
  String? _usernameError;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
    _userNameFocus.addListener(() => _onFocusChanged(_userNameFocus, _userNameKey));
    _firstNameFocus.addListener(() => _onFocusChanged(_firstNameFocus, _firstNameKey));
    _emailFocus.addListener(() => _onFocusChanged(_emailFocus, _emailKey));
    _phoneFocus.addListener(() => _onFocusChanged(_phoneFocus, _phoneKey));
    _passwordFocus.addListener(() => _onFocusChanged(_passwordFocus, _passwordKey));
    _confirmPasswordFocus.addListener(() => _onFocusChanged(_confirmPasswordFocus, _confirmPasswordKey));
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

  // Function to pick an image
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
              Container(
                key: _userNameKey,
                child: TextFormField(
                  controller: _userNameController,
                  focusNode: _userNameFocus,
                  validator: validateUsername,
                  decoration: const InputDecoration(
                    hintText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // FirstName Field
              Container(
                key: _firstNameKey,
                child: TextFormField(
                  controller: _firstNameController,
                  focusNode: _firstNameFocus,
                  validator: validateFirstName,
                  decoration: const InputDecoration(
                    hintText: 'First Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Email Field
              Container(
                key: _emailKey,
                child: TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                key: _phoneKey,
                child: TextFormField(
                  controller: _phoneNumberController,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  validator: validatePhoneNumber,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              Container(
                key: _passwordKey,
                child: TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  validator: validatePassword,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              Container(
                key: _confirmPasswordKey,
                child: TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  obscureText: true,
                  validator: (value) =>
                      validateConfirmPassword(value, _passwordController.text),
                  decoration: const InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Consumer to listen to RegisterViewModel
              Consumer<RegisterViewModel>(
                builder: (context, viewModel, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (viewModel.status.type == StatusType.failure) {
                      Fluttertoast.showToast(
                        msg: viewModel.status.message ?? "",
                      );
                    } else if (viewModel.status.type == StatusType.success) {
                      Fluttertoast.showToast(msg: "Registration Successful");

                      // Clear form fields after successful registration
                      _emailController.clear();
                      _passwordController.clear();
                      _confirmPasswordController.clear();

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
                                    viewModel.register(
                                      _firstNameController.text,
                                      _emailController.text,
                                      _userNameController.text,
                                      _phoneNumberController.text,
                                      _passwordController.text,
                                      _selectedImage,
                                    );
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
