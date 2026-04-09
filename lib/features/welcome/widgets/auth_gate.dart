import 'package:cherry_mvp/features/home/home_page.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold();
        }

        // If user is logged in then go to home page
        if (snapshot.hasData) {
          return const HomePage();
        }

        // If user is not logged in then go to the WelcomePage
        return const WelcomePage();
      },
    );
  }
}
