import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UsernameSetupPage extends StatefulWidget {
  const UsernameSetupPage({super.key});

  @override
  State<UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<UsernameSetupPage> {
  final TextEditingController _usernameController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  String? _validateUsername() {
    return validateUsername(_usernameController.text.trim());
  }

  bool get _isValid => _validateUsername() == null;

  Future<void> _handleBack() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    context.read<NavigationProvider>().navigateToAndRemoveUntil(
      AppRoutes.welcome,
      (route) => false,
    );
  }

  Future<void> _saveUsername() async {
    final validationError = _validateUsername();
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _handleBack();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final username = _usernameController.text.trim();
    final isTakenResult = await UsernameService.isUsernameTaken(
      username,
      excludeUid: user.uid,
    );

    if (!mounted) return;

    if (!isTakenResult.isSuccess) {
      setState(() {
        _isSubmitting = false;
        _errorText = isTakenResult.error ?? AppLocalizations.of(context)!.authUsernameSaveFailed;
      });
      return;
    }

    if (isTakenResult.value == true) {
      setState(() {
        _isSubmitting = false;
        _errorText = AppLocalizations.of(context)!.authUsernameTakenError;
      });
      return;
    }

    final saveResult = await UsernameService.saveUsername(user.uid, username);

    if (!mounted) return;

    if (!saveResult.isSuccess) {
      setState(() {
        _isSubmitting = false;
        _errorText = saveResult.error ?? AppLocalizations.of(context)!.authUsernameSaveFailed;
      });
      return;
    }

    setState(() => _isSubmitting = false);
    context.read<NavigationProvider>().replaceWith(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        await _handleBack();
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _isSubmitting ? null : _handleBack,
                      icon: Image.asset(
                        AppImages.backIcon,
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const Spacer(),
                    Image.asset(AppImages.cherryLogo, width: 86),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.authUsernameSetupTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authUsernameSetupSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _usernameController,
                  enabled: !_isSubmitting,
                  onChanged: (_) {
                    setState(() {
                      _errorText = null;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: l10n.authUsernameSetupHint,
                    prefixIcon: const Icon(Icons.person_outline),
                    errorText: _errorText,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton(
                          onPressed: _isValid ? _saveUsername : null,
                          child: Text(l10n.commonNext),
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
