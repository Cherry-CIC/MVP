String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return "Password cannot be empty";
  }
  if (value.length < 6) {
    return "Password must be at least 6 characters";
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return "Email cannot be empty";
  }
  if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]+$").hasMatch(value)) {
    return "Please enter a valid email";
  }
  return null;
}

String? validateUsername(String? value) {
  if (value == null || value.isEmpty) {
    return 'Username is required.';
  }
  if (value.length < 3 || value.length > 20) {
    return 'Username must be between 3 and 20 characters.';
  }
  final regex = RegExp(r'^[a-zA-Z0-9_]+$');
  if (!regex.hasMatch(value)) {
    return 'Username can only contain letters, numbers, and underscores.';
  }
  return null;
}

String? validateFirstName(String? value) {
  if (value == null || value.isEmpty) {
    return "First name cannot be empty";
  }
  if (value.length < 2) {
    return "First name must be at least 2 characters";
  }
  if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
    return "First name can only contain letters and spaces";
  }
  return null;
}

String? validatePhoneNumber(String? value) {
  if (value == null || value.isEmpty) {
    return "Phone number cannot be empty";
  }
  RegExp regExp = RegExp(r"^(?:\+44|0)\d{9,10}$");
  if (!regExp.hasMatch(value)) {
    return "Please enter a valid UK phone number";
  }
  return null;
}

String? validateConfirmPassword(String? value, String? password) {
  if (value == null || value.isEmpty) {
    return "Confirm your password";
  }
  if (value != password) {
    return "Passwords do not match";
  }
  return null;
}


String? validateDonationFormFields(String? value) {
  if (value == null || value.isEmpty) {
    return "This cannot be empty";
  }
  if (value.length < 2) {
    return "This must be at least 2 characters";
  }
  if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
    return "This can only contain letters and spaces";
  }
  return null;
}

String? validateOptionalDonationFormFields(String? value) {
  // Optional field - no validation if empty
  if (value == null || value.isEmpty) {
    return null;
  }
  if (value.length < 2) {
    return "This must be at least 2 characters";
  }
  if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
    return "This can only contain letters and spaces";
  }
  return null;
}