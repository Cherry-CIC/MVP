import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/router/router.dart';

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
  // Image picker controller
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

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

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              GestureDetector(
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
              const SizedBox(height: 20),

              // Username Field
              TextFormField(
                controller: _userNameController,
                validator: validateUsername,
                decoration: InputDecoration(
                  hintText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  suffixIcon: isUsernameChecking
                      ? const Padding(
                          // Show spinner while checking
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _usernameError == null && validateUsername == null
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ) // Show checkmark on success
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // FirstName Field
              TextFormField(
                controller: _firstNameController,
                validator: validateFirstName,
                decoration: InputDecoration(
                  hintText: 'First Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                validator: validatePhoneNumber,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: validatePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) =>
                    validateConfirmPassword(value, _passwordController.text),
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock),
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
                                child: Text("Submit"),
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
                    Text("Already have an account? "),
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
