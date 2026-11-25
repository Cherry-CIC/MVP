import 'dart:async';

import 'package:cherry_mvp/core/services/firebase_auth_service.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/welcome/widgets/email_action_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({required this.uid, required this.email, super.key});

  final String uid;
  final String email;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> with WidgetsBindingObserver {
  late final _service = context.read<FirebaseAuthService>();
  late final StreamSubscription<User?> _session;
  bool _leaving = false;
  bool _checking = false;
  bool _sending = false;
  bool _signingOut = false;
  String? _feedback;

  bool get _active => mounted && !_leaving && !_signingOut && ModalRoute.of(context)?.isCurrent == true;
  bool get _sameUser => _service.firebaseAuth.currentUser?.uid == widget.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = _service.firebaseAuth.authStateChanges().listen((user) {
      if (_active && user?.uid != widget.uid && !_sameUser) _continue();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  void _continue() {
    if (!_active) return;
    _leaving = true;
    Navigator.of(context).pop();
  }

  Future<void> _check() async {
    if (!_active || !_sameUser || _checking) return;
    setState(() => _checking = true);
    try {
      await _service.firebaseAuth.currentUser!.reload();
      if (!_active || !_sameUser) return;
      if (_service.firebaseAuth.currentUser!.emailVerified) {
        _continue();
      } else {
        setState(() => _feedback = 'Your email is still unverified. Open the link in your email, then check again.');
      }
    } catch (_) {
      if (_active && _sameUser) setState(() => _feedback = 'Unable to check your email. Please try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (!_active || !_sameUser || _sending) return;
    setState(() => _sending = true);
    final result = await _service.sendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (_active && _sameUser) {
        _feedback = result.isSuccess ? 'Verification email sent.' : 'Unable to resend the email. Please try again.';
      }
    });
  }

  Future<void> _signOut() async {
    if (!_active || !_sameUser) return;
    setState(() => _signingOut = true);
    await context.read<AuthViewModel>().logout(context);
    if (mounted) {
      setState(() => _signingOut = false);
      if (!_sameUser) _continue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_signingOut,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _leaving = true;
      },
      child: EmailActionPage(
        title: 'Verify your email',
        email: widget.email,
        message:
            'Check your inbox and junk folder for your verification link. You can use cherry now and verify your email later.',
        actions: [
          if (_feedback != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(liveRegion: true, child: Text(_feedback!)),
            ),
          FilledButton(
            onPressed: _checking || _signingOut ? null : _check,
            child: Text(_checking ? 'Checking…' : 'I’ve verified my email'),
          ),
          OutlinedButton(onPressed: _signingOut ? null : _continue, child: const Text('Continue for now')),
          TextButton(
            onPressed: _sending || _signingOut ? null : _resend,
            child: Text(_sending ? 'Sending…' : 'Resend verification email'),
          ),
          const Divider(height: 32),
          const Text('Used the wrong address? Your account and username have already been created.'),
          TextButton(onPressed: _signingOut ? null : _signOut, child: const Text('Sign out and return to login')),
        ],
      ),
    );
  }
}
