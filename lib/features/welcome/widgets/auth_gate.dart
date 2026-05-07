import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/register/verify_email_page.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:cherry_mvp/features/welcome/widgets/post_auth_username_gate.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = context.read<FirebaseAuth>();

    return StreamBuilder<User?>(
      stream: firebaseAuth.userChanges(),
      builder: (context, snapshot) {
        // Show splash while checking auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold();
        }

        final user = snapshot.data;
        if (user != null) {
          // If user is logged in and the email has been verified, then go to home page,
          // else show the check your email page
          if (user.emailVerified) {
            return const PostAuthUsernameGate();
          } else {
            return const VerifyEmailPage();
          }
        }

        // If user is not logged in then go to the WelcomePage
        return const WelcomePage();
      },
    );
  }
}
