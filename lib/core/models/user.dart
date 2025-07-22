class User {
  final String name;
  final String email;
  final String phoneNumber;

  User({required this.name, required this.email, required this.phoneNumber});
}

class UserCredentials {
  final String? uid;
  final String? email;
  final String? firstname;
  final String? photoUrl;
  final String? phonenumber;

  UserCredentials({
    required this.uid,
    required this.email,
    this.firstname,
    this.photoUrl,
    this.phonenumber,
  });
}
