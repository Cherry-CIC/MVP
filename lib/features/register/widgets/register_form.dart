import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/register/register_viewmodel.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';
import 'package:cherry_mvp/core/router/router.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
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
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
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
                        color: AppColors.greyTextColor,
                        child: Center(
                            child: Icon(Icons.camera_alt,
                                color: AppColors.primary)),
                      )
                    : Image.file(
                        _selectedImage!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 20),

              // FirstName Field
              TextFormField(
                controller: _firstNameController,
                validator: validateFirstName,
                decoration: InputDecoration(
                    hintText: 'First Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                decoration:
                    InputDecoration(hintText: 'Email', icon: Icon(Icons.email)),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                validator: validatePhoneNumber,
                decoration: InputDecoration(
                    hintText: 'Phone Number', icon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: validatePassword,
                decoration: InputDecoration(
                    hintText: 'Password', icon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) =>
                    validateConfirmPassword(value, _passwordController.text),
                decoration: InputDecoration(
                    hintText: 'Confirm Password', icon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 20),

              // Consumer to listen to RegisterViewModel
              Consumer<RegisterViewModel>(
                builder: (context, viewModel, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (viewModel.status.type == StatusType.failure) {
                      Fluttertoast.showToast(
                          msg: viewModel.status.message ?? "");
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
                          ? const LoadingView()
                          : SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    viewModel.register(
                                        _firstNameController.text,
                                        _emailController.text,
                                        _phoneNumberController.text,
                                        _passwordController.text,
                                        _selectedImage);
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
                    Text("Login",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
