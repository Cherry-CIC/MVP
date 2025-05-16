import 'dart:io';

class RegisterRequest {
  final String firstname;
  final String email;
  final String phone;
  final String password;
  final File? imageFile;

  RegisterRequest({required this.firstname, required this.email, required this.phone, required this.password, required this.imageFile});
}
