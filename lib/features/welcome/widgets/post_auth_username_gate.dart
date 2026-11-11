import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/google_auth_service.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cherry_mvp/features/auth/username_setup_page.dart';
import 'package:cherry_mvp/features/home/home_page.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostAuthUsernameGate extends StatefulWidget {
  final Future<Result<String?>> Function(String uid)? usernameResolver;
  final User? currentUserOverride;
  final Future<void> Function()? signOutHandler;
  final FirebaseAuth? firebaseAuth;
  final GoogleAuthService? googleAuthService;
  final SharedPreferences? preferences;
  final WidgetBuilder? homeBuilder;
  final WidgetBuilder? usernameSetupBuilder;

  const PostAuthUsernameGate({
    super.key,
    this.usernameResolver,
    this.currentUserOverride,
    this.signOutHandler,
    this.firebaseAuth,
    this.googleAuthService,
    this.preferences,
    this.homeBuilder,
    this.usernameSetupBuilder,
  });

  @override
  State<PostAuthUsernameGate> createState() => _PostAuthUsernameGateState();
}

class _PostAuthUsernameGateState extends State<PostAuthUsernameGate> {
  String? _uid;
  Future<Result<String?>>? _usernameFuture;

  Future<Result<String?>> _resolveUsername(String uid) {
    final resolver = widget.usernameResolver ?? UsernameService.resolveUsername;
    return resolver(uid);
  }

  void _retry(String uid) {
    setState(() {
      _usernameFuture = _resolveUsername(uid);
    });
  }

  Future<void> _handleSignOut() async {
    final handler = widget.signOutHandler;
    if (handler != null) {
      await handler();
    } else {
      await _defaultSignOut();
    }
    if (!mounted) return;
    setState(() {
      _uid = null;
      _usernameFuture = null;
    });
  }

  Future<void> _defaultSignOut() async {
    try {
      final auth = widget.firebaseAuth ?? FirebaseAuth.instance;
      await auth.signOut();
    } catch (_) {}

    try {
      final googleAuth = widget.googleAuthService ?? GoogleAuthService();
      await googleAuth.signOut();
    } catch (_) {}

    try {
      final prefs = widget.preferences ?? await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.currentUserOverride ??
        (widget.firebaseAuth ?? FirebaseAuth.instance).currentUser;

    if (currentUser == null) {
      return const WelcomePage();
    }

    if (_uid != currentUser.uid || _usernameFuture == null) {
      _uid = currentUser.uid;
      _usernameFuture = _resolveUsername(currentUser.uid);
    }

    return FutureBuilder<Result<String?>>(
      future: _usernameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data;
        if (snapshot.hasError || result == null || !result.isSuccess) {
          return _buildErrorState(context, currentUser.uid);
        }

        final username = result.value?.trim();
        if (username != null && username.isNotEmpty) {
          return widget.homeBuilder != null ? widget.homeBuilder!(context) : const HomePage();
        }

        return widget.usernameSetupBuilder != null
            ? widget.usernameSetupBuilder!(context)
            : const UsernameSetupPage();
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String uid) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppImages.cherryLogo, width: 86),
                const SizedBox(height: 24),
                Text(
                  'Unable to load profile',
                  key: const Key('post_auth_error_title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We couldn\'t verify your profile details. Please check your connection and try again.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    key: const Key('post_auth_retry_button'),
                    onPressed: () => _retry(uid),
                    child: const Text('Try Again'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    key: const Key('post_auth_sign_out_button'),
                    onPressed: _handleSignOut,
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
