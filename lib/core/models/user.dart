import 'package:firebase_auth/firebase_auth.dart';

class UserCredentials {
  final String? uid;
  final String? email;
  final String? firstname;
  final String? photoUrl;
  final String? phoneNumber;

  UserCredentials({
    required this.uid,
    required this.email,
    this.firstname,
    this.photoUrl,
    this.phoneNumber,
  });

  factory UserCredentials.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserCredentials(
      uid: uid,
      email: data['email'],
      firstname: data['firstname'],
      photoUrl: data['photoUrl'],
    );
  }

  factory UserCredentials.fromAuth(User user) {
    return UserCredentials(
      uid: user.uid,
      email: user.email,
      firstname: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
