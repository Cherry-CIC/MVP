String? validatePassword(String? value) {
  final password = value?.trim() ?? '';

  if (password.isEmpty) {
    return "Password cannot be empty";
  }
  if (password.length < 6) {
    return "Password must be at least 6 characters";
  }
  return null;
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';

  if (email.isEmpty) {
    return "Email cannot be empty";
  }
  if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$").hasMatch(email)) {
    return "Please enter a valid email";
  }
  return null;
}

String? validateUsername(String? value) {
  final username = value?.trim() ?? '';

  if (username.isEmpty) {
    return 'Username is required.';
  }
  if (username.length < 3 || username.length > 20) {
    return 'Username must be between 3 and 20 characters.';
  }
  final regex = RegExp(r'^[a-zA-Z0-9_]+$');
  if (!regex.hasMatch(username)) {
    return 'Username can only contain letters, numbers, and underscores.';
  }
  return null;
}

String? validateFirstName(String? value) {
  final firstName = value?.trim() ?? '';

  if (firstName.isEmpty) {
    return "First name cannot be empty";
  }
  if (firstName.length < 2) {
    return "First name must be at least 2 characters";
  }
  if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(firstName)) {
    return "First name can only contain letters and spaces";
  }
  return null;
}

String? validatePhoneNumber(String? value) {
  final phoneNumber = value?.trim() ?? '';

  if (phoneNumber.isEmpty) {
    return "Phone number cannot be empty";
  }
  final regExp = RegExp(r"^(?:\+44|0)\d{9,10}$");
  if (!regExp.hasMatch(phoneNumber)) {
    return "Please enter a valid UK phone number";
  }
  return null;
}

String? validateConfirmPassword(String? value, String? password) {
  final confirmPassword = value ?? '';
  final originalPassword = password ?? '';

  if (confirmPassword.isEmpty) {
    return "Confirm your password";
  }
  if (confirmPassword != originalPassword) {
    return "Passwords do not match";
  }
  return null;
}

String? validateDonationFormFields(String? value) {
  final field = value?.trim() ?? '';

  if (field.isEmpty) {
    return "This cannot be empty";
  }
  if (field.length < 2) {
    return "This must be at least 2 characters";
  }
  if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(field)) {
    return "This can only contain letters and spaces";
  }
  return null;
}

String? validateOptionalDonationFormFields(String? value) {
  final field = value?.trim() ?? '';

  if (field.isEmpty) {
    return null;
  }
  if (field.length < 2) {
    return "This must be at least 2 characters";
  }
  if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(field)) {
    return "This can only contain letters and spaces";
  }
  return null;
}