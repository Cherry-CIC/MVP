import 'package:firebase_auth/firebase_auth.dart';

class UserCredentials {
  final String? uid;
  final String? email;
  final String? username;
  final String? firstname;
  final String? photoUrl;
  final String? photoStoragePath;
  final String? phoneNumber;

  UserCredentials({
    required this.uid,
    required this.email,
    this.username,
    this.firstname,
    this.photoUrl,
    this.photoStoragePath,
    this.phoneNumber,
  });

  factory UserCredentials.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserCredentials(
      uid: uid,
      email: data['email'],
      username: data['username'],
      firstname: data['firstname'],
      photoUrl: data['photoUrl'],
      photoStoragePath: data['photoStoragePath'],
      phoneNumber: data['phone'],
    );
  }

  factory UserCredentials.fromAuth(User user) {
    return UserCredentials(
      uid: user.uid,
      email: user.email,
      firstname: user.displayName,
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'UserCredentials{uid: $uid, username: $username, firstname: $firstname, photoUrl: $photoUrl}';
  }
}
