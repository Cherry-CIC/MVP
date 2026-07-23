import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';

class SettingsFooter extends StatefulWidget {
  const SettingsFooter({super.key});

  @override
  State<SettingsFooter> createState() => _SettingsFooterState();
}

class _SettingsFooterState extends State<SettingsFooter> {
  bool _isDeletingAccount = false;

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
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

  @override
  Widget build(BuildContext context) {
    return SliverList.list(
      children: [
        ListTile(
          title: Text(AppStrings.deleteAccountText),
          textColor: Theme.of(context).colorScheme.primary,
          trailing: _isDeletingAccount
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: () async {
            if (_isDeletingAccount) return;

            final confirm = await _showConfirmDialog(context);
            if (confirm != true) return;
            if (!context.mounted) return;

            setState(() => _isDeletingAccount = true);
            final result = await context.read<AuthViewModel>().deleteAccount();

            if (!context.mounted) return;
            setState(() => _isDeletingAccount = false);

            if (!result.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.error ?? 'Failed to delete account')),
              );
            }
          },
        ),
        ListTile(
          title: Text(AppStrings.appName),
          titleTextStyle: Theme.of(context).textTheme.titleMedium,
          subtitle: Text(AppStrings.appVersion),
          subtitleTextStyle: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}
