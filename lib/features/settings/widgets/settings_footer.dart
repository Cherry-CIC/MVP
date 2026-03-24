import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/services.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';

class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLoadingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverList.list(children: [
      ListTile(
        title: Text(AppStrings.deleteAccountText),
        textColor: Theme.of(context).colorScheme.primary,
        onTap: () async {
          final confirm = await _showConfirmDialog(context);
          if (confirm != true) return;

          // show loading
          _showLoadingDialog(context);

          try {
            final apiService = Provider.of<ApiService>(context, listen: false);
            final result = await apiService.delete(ApiEndpoints.deleteAccount);

            // Temporary: pause here if a Dart debugger is attached
            // import dart:developer as developer at top when using this in real debug
            // developer.debugger();

            // dismiss loading
            if (context.mounted) Navigator.of(context).pop();

            if (result.isSuccess) {
              // On successful account deletion, log the user out and navigate to welcome
              if (context.mounted) {
                final authViewModel =
                    Provider.of<AuthViewModel>(context, listen: false);
                await authViewModel.logout(context);
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.error ?? 'Failed to delete account')),
                );
              }
            }
          } catch (e) {
            if (context.mounted) Navigator.of(context).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          }
        },
      ),
      ListTile(
        title: Text(AppStrings.appName),
        titleTextStyle: Theme.of(context).textTheme.titleMedium,
        subtitle: Text(AppStrings.appVersion),
        subtitleTextStyle: Theme.of(context).textTheme.labelLarge,
      ),
    ]);
  }
}
