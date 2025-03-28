class User {
  final String name;
  final String email;
  final String phoneNumber;

  User({
    required this.name,
    required this.email,
    required this.phoneNumber
  });
}

class UserCredentials {
  final String? uid;
  final String? email;

  UserCredentials({
    required this.uid,
    required this.email,
  });
}
