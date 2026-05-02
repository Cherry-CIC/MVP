import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/services/firebase_auth_service.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;
  late final FirebaseAuthService _firebaseAuthService;

  @override
  void initState() {
    super.initState();
    _firebaseAuthService = context.read<FirebaseAuthService>();
    _timer = Timer.periodic(Duration(seconds: 3), (_) => _firebaseAuthService.firebaseAuth.currentUser?.reload());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          spacing: 50,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Check your email inbox for a Verification email'),
            ElevatedButton(
              onPressed: () async => await _firebaseAuthService.sendVerificationEmail(),
              child: Text('Resend Verification Email'),
            ),
          ],
        ),
      ),
    );
  }
}
