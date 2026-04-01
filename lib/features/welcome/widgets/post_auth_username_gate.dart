import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/features/auth/username_setup_page.dart';
import 'package:cherry_mvp/features/home/home_page.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostAuthUsernameGate extends StatefulWidget {
  const PostAuthUsernameGate({super.key});

  @override
  State<PostAuthUsernameGate> createState() => _PostAuthUsernameGateState();
}

class _PostAuthUsernameGateState extends State<PostAuthUsernameGate> {
  String? _uid;
  Future<String?>? _usernameFuture;

  Future<String?> _resolveUsername(String uid) {
    return UsernameService.getUsername(uid);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const WelcomePage();
    }

    if (_uid != currentUser.uid || _usernameFuture == null) {
      _uid = currentUser.uid;
      _usernameFuture = _resolveUsername(currentUser.uid);
    }

    return FutureBuilder<String?>(
      future: _usernameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const UsernameSetupPage();
        }

        final username = snapshot.data?.trim();
        if (username != null && username.isNotEmpty) {
          return const HomePage();
        }

        return const UsernameSetupPage();
      },
    );
  }
}
